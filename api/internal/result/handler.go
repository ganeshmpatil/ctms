package result

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
	mux.HandleFunc("GET /results", h.list)
	mux.HandleFunc("POST /results", h.create)
	mux.HandleFunc("PATCH /results/{id}", h.update)
	mux.HandleFunc("DELETE /results/{id}", h.delete)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]Result, 0)
	q := h.db.WithContext(r.Context()).Preload("Subjects").Order("year DESC, month DESC")

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
		q = q.Where("student_id IN ?", ids)
	} else if sid := r.URL.Query().Get("student_id"); sid != "" {
		q = q.Where("student_id = ?", sid)
	}

	if err := q.Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var res Result
	if err := httpx.DecodeJSON(r, &res); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if res.StudentID == uuid.Nil || res.Year == 0 || res.Month < 1 || res.Month > 12 {
		httpx.BadRequest(w, "student_id, year, month (1..12) required")
		return
	}
	if err := h.db.WithContext(r.Context()).Create(&res).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, res)
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var patch struct {
		Year       *int     `json:"year"`
		Month      *int     `json:"month"`
		TotalMarks *float64 `json:"total_marks"`
		Photo      *string  `json:"photo"`
	}
	if err := httpx.DecodeJSON(r, &patch); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}

	updates := map[string]any{}
	if patch.Year != nil {
		updates["year"] = *patch.Year
	}
	if patch.Month != nil {
		if *patch.Month < 1 || *patch.Month > 12 {
			httpx.BadRequest(w, "month must be 1..12")
			return
		}
		updates["month"] = *patch.Month
	}
	if patch.TotalMarks != nil {
		updates["total_marks"] = *patch.TotalMarks
	}
	if patch.Photo != nil {
		updates["photo"] = *patch.Photo
	}

	var res Result
	tx := h.db.WithContext(r.Context())
	if err := tx.First(&res, "id = ?", id).Error; err != nil {
		if httpx.IsNotFound(err) {
			httpx.NotFound(w)
			return
		}
		httpx.ServerError(w, err)
		return
	}
	if len(updates) > 0 {
		if err := tx.Model(&res).Updates(updates).Error; err != nil {
			httpx.ServerError(w, err)
			return
		}
	}
	httpx.WriteJSON(w, http.StatusOK, res)
}

func (h *Handler) delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	tx := h.db.WithContext(r.Context()).Delete(&Result{}, "id = ?", id)
	if tx.Error != nil {
		httpx.ServerError(w, tx.Error)
		return
	}
	if tx.RowsAffected == 0 {
		httpx.NotFound(w)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
