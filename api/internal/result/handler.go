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
