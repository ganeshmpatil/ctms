package attendance

import (
	"net/http"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"school-api/internal/auth"
	"school-api/internal/httpx"
	"school-api/internal/parent"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /attendance", h.list)
	mux.HandleFunc("POST /attendance", h.create)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]Attendance, 0)
	q := h.db.WithContext(r.Context()).Order("date DESC")

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
	if d := r.URL.Query().Get("date"); d != "" {
		q = q.Where("date = ?", d)
	}
	if err := q.Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var a Attendance
	if err := httpx.DecodeJSON(r, &a); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if a.StudentID == uuid.Nil || a.Date.IsZero() {
		httpx.BadRequest(w, "student_id and date required")
		return
	}
	if a.IsPresent == a.IsAbsent {
		httpx.BadRequest(w, "exactly one of is_present / is_absent must be true")
		return
	}
	err := h.db.WithContext(r.Context()).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "student_id"}, {Name: "date"}},
		DoUpdates: clause.AssignmentColumns([]string{"is_present", "is_absent", "absent_reason"}),
	}).Create(&a).Error
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, a)
}
