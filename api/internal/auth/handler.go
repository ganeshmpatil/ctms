package auth

import (
	"errors"
	"net/http"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"school-api/internal/httpx"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("POST /auth/register", h.register)
	mux.HandleFunc("POST /auth/login", h.login)
	mux.HandleFunc("GET /auth/me", h.me)
	mux.HandleFunc("POST /me/password", h.changePassword)
	mux.HandleFunc("GET /admin/users", h.listUsers)
	mux.HandleFunc("POST /admin/users/{id}/reset-password", h.adminResetPassword)
}

var allowedRoles = map[string]bool{
	"admin": true, "teacher": true, "staff": true, "parent": true,
}

func (h *Handler) register(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email     string  `json:"email"`
		Password  string  `json:"password"`
		Role      string  `json:"role"`
		FirstName *string `json:"first_name"`
		LastName  *string `json:"last_name"`
		Phone     *string `json:"phone"`
	}
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if req.Email == "" || req.Password == "" {
		httpx.BadRequest(w, "email and password required")
		return
	}
	if !allowedRoles[req.Role] {
		httpx.BadRequest(w, "role must be admin, teacher, staff, or parent")
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	u := User{
		Email:        req.Email,
		PasswordHash: string(hash),
		Role:         req.Role,
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Phone:        req.Phone,
	}
	if err := h.db.WithContext(r.Context()).Create(&u).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, u)
}

func (h *Handler) login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	var u User
	err := h.db.WithContext(r.Context()).First(&u, "email = ?", req.Email).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		httpx.WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": "invalid credentials"})
		return
	}
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(req.Password)); err != nil {
		httpx.WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": "invalid credentials"})
		return
	}
	tok, err := SignJWT(&u)
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"token": tok,
		"user":  u,
	})
}

func (h *Handler) me(w http.ResponseWriter, r *http.Request) {
	authz := r.Header.Get("Authorization")
	if len(authz) < 8 {
		httpx.WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": "missing bearer token"})
		return
	}
	claims, err := ParseJWT(authz[7:])
	if err != nil {
		httpx.WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": err.Error()})
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"id":    claims.UserID,
		"email": claims.Email,
		"role":  claims.Role,
		"exp":   claims.ExpiresAt,
	})
}

// changePassword lets the logged-in user change their own password.
// Requires the current password as confirmation.
func (h *Handler) changePassword(w http.ResponseWriter, r *http.Request) {
	id := IdentityFromCtx(r.Context())
	if id == nil {
		httpx.WriteJSON(w, http.StatusUnauthorized,
			map[string]string{"error": "unauthenticated"})
		return
	}

	var req struct {
		CurrentPassword string `json:"current_password"`
		NewPassword     string `json:"new_password"`
	}
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if len(req.NewPassword) < 6 {
		httpx.BadRequest(w, "new_password must be at least 6 characters")
		return
	}

	var u User
	if err := h.db.WithContext(r.Context()).First(&u, "id = ?", id.ID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			httpx.NotFound(w)
			return
		}
		httpx.ServerError(w, err)
		return
	}
	if err := bcrypt.CompareHashAndPassword(
		[]byte(u.PasswordHash), []byte(req.CurrentPassword)); err != nil {
		httpx.WriteJSON(w, http.StatusUnauthorized,
			map[string]string{"error": "current password is incorrect"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	if err := h.db.WithContext(r.Context()).
		Model(&u).
		Update("password_hash", string(hash)).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// listUsers returns all auth users (admin only).
func (h *Handler) listUsers(w http.ResponseWriter, r *http.Request) {
	out := make([]User, 0)
	if err := h.db.WithContext(r.Context()).
		Order("role, email").
		Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

// adminResetPassword lets an admin set any user's password to a new value.
// No "current password" check — admin is trusted.
func (h *Handler) adminResetPassword(w http.ResponseWriter, r *http.Request) {
	userID := r.PathValue("id")
	var req struct {
		NewPassword string `json:"new_password"`
	}
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if len(req.NewPassword) < 6 {
		httpx.BadRequest(w, "new_password must be at least 6 characters")
		return
	}

	var u User
	if err := h.db.WithContext(r.Context()).First(&u, "id = ?", userID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			httpx.NotFound(w)
			return
		}
		httpx.ServerError(w, err)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	if err := h.db.WithContext(r.Context()).
		Model(&u).
		Update("password_hash", string(hash)).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
