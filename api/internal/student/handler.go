package student

import (
	"net/http"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"school-api/internal/auth"
	"school-api/internal/httpx"
	"school-api/internal/parent"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /students", h.list)
	mux.HandleFunc("POST /students", h.create)
	mux.HandleFunc("GET /students/{id}", h.get)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]Student, 0)
	q := h.db.WithContext(r.Context()).Order("created_at DESC")

	id := auth.IdentityFromCtx(r.Context())
	if id != nil && id.Role == "parent" {
		ids, err := parent.StudentIDsForParent(r.Context(), h.db, id.ID)
		if err != nil {
			httpx.ServerError(w, err)
			return
		}
		if len(ids) == 0 {
			httpx.WriteJSON(w, http.StatusOK, out)
			return
		}
		q = q.Where("id IN ?", ids)
	} else if div := r.URL.Query().Get("division_id"); div != "" {
		q = q.Where("division_id = ?", div)
	}

	if err := q.Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	studentID := r.PathValue("id")

	id := auth.IdentityFromCtx(r.Context())
	if id != nil && id.Role == "parent" {
		ok, err := parent.IsParentOfStudent(r.Context(), h.db, id.ID, studentID)
		if err != nil {
			httpx.ServerError(w, err)
			return
		}
		if !ok {
			httpx.WriteJSON(w, http.StatusForbidden,
				map[string]string{"error": "this student is not linked to your account"})
			return
		}
	}

	var s Student
	err := h.db.WithContext(r.Context()).First(&s, "id = ?", studentID).Error
	if httpx.IsNotFound(err) {
		httpx.NotFound(w)
		return
	}
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, s)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var s Student
	if err := httpx.DecodeJSON(r, &s); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if s.Name == "" || s.DivisionID == uuid.Nil {
		httpx.BadRequest(w, "name and division_id required")
		return
	}
	if err := h.db.WithContext(r.Context()).Create(&s).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, s)
}
