package attendance

import (
	"net/http"
	"time"

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
	var req struct {
		StudentID    string  `json:"student_id"`
		Date         string  `json:"date"`
		IsPresent    bool    `json:"is_present"`
		IsAbsent     bool    `json:"is_absent"`
		AbsentReason *string `json:"absent_reason"`
	}
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}

	studentID, err := uuid.Parse(req.StudentID)
	if err != nil {
		httpx.BadRequest(w, "invalid student_id")
		return
	}

	date, err := parseDate(req.Date)
	if err != nil {
		httpx.BadRequest(w, "date must be YYYY-MM-DD or RFC3339; got: "+req.Date)
		return
	}

	if req.IsPresent == req.IsAbsent {
		httpx.BadRequest(w, "exactly one of is_present / is_absent must be true")
		return
	}

	a := Attendance{
		StudentID:    studentID,
		Date:         date,
		IsPresent:    req.IsPresent,
		IsAbsent:     req.IsAbsent,
		AbsentReason: req.AbsentReason,
	}
	err = h.db.WithContext(r.Context()).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "student_id"}, {Name: "date"}},
		DoUpdates: clause.AssignmentColumns([]string{"is_present", "is_absent", "absent_reason"}),
	}).Create(&a).Error
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, a)
}

// parseDate accepts either bare YYYY-MM-DD or full RFC3339, returns UTC midnight.
func parseDate(s string) (time.Time, error) {
	if t, err := time.Parse("2006-01-02", s); err == nil {
		return t, nil
	}
	return time.Parse(time.RFC3339, s)
}
