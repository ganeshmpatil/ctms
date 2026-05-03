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
	mux.HandleFunc("PATCH /students/{id}", h.update)
	mux.HandleFunc("DELETE /students/{id}", h.delete)
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

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var patch struct {
		Name          *string `json:"name"`
		Address       *string `json:"address"`
		DivisionID    *string `json:"division_id"`
		GuardianPhone *string `json:"guardian_phone"`
		PhotoURL      *string `json:"photo_url"`
		SchoolID      *string `json:"school_id"`
	}
	if err := httpx.DecodeJSON(r, &patch); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}

	updates := map[string]any{}
	if patch.Name != nil {
		updates["name"] = *patch.Name
	}
	if patch.Address != nil {
		updates["address"] = *patch.Address
	}
	if patch.DivisionID != nil {
		div, err := uuid.Parse(*patch.DivisionID)
		if err != nil {
			httpx.BadRequest(w, "invalid division_id")
			return
		}
		updates["division_id"] = div
	}
	if patch.GuardianPhone != nil {
		updates["guardian_phone"] = *patch.GuardianPhone
	}
	if patch.PhotoURL != nil {
		updates["photo_url"] = *patch.PhotoURL
	}
	if patch.SchoolID != nil {
		sid, err := uuid.Parse(*patch.SchoolID)
		if err != nil {
			httpx.BadRequest(w, "invalid school_id")
			return
		}
		updates["school_id"] = sid
	}

	var s Student
	tx := h.db.WithContext(r.Context())
	if err := tx.First(&s, "id = ?", id).Error; err != nil {
		if httpx.IsNotFound(err) {
			httpx.NotFound(w)
			return
		}
		httpx.ServerError(w, err)
		return
	}
	if len(updates) > 0 {
		if err := tx.Model(&s).Updates(updates).Error; err != nil {
			httpx.ServerError(w, err)
			return
		}
	}
	httpx.WriteJSON(w, http.StatusOK, s)
}

func (h *Handler) delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	res := h.db.WithContext(r.Context()).Delete(&Student{}, "id = ?", id)
	if res.Error != nil {
		httpx.ServerError(w, res.Error)
		return
	}
	if res.RowsAffected == 0 {
		httpx.NotFound(w)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
