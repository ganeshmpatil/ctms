package parent

import (
	"net/http"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"school-api/internal/auth"
	"school-api/internal/httpx"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /parent-students", h.list)
	mux.HandleFunc("POST /parent-students", h.link)
	mux.HandleFunc("DELETE /parent-students/{id}", h.unlink)
}

// list returns parent↔student links.
// - admin/teacher/staff: see all (optionally filter via ?parent_id=)
// - parent: only their own links (parent_id forced to identity)
func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	id := auth.IdentityFromCtx(r.Context())
	q := h.db.WithContext(r.Context()).Order("created_at DESC")

	if id != nil && id.Role == "parent" {
		q = q.Where("parent_id = ?", id.ID)
	} else if pid := r.URL.Query().Get("parent_id"); pid != "" {
		q = q.Where("parent_id = ?", pid)
	}

	out := make([]ParentStudent, 0)
	if err := q.Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) link(w http.ResponseWriter, r *http.Request) {
	var req struct {
		ParentID  string `json:"parent_id"`
		StudentID string `json:"student_id"`
	}
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	pid, err := uuid.Parse(req.ParentID)
	if err != nil {
		httpx.BadRequest(w, "invalid parent_id")
		return
	}
	sid, err := uuid.Parse(req.StudentID)
	if err != nil {
		httpx.BadRequest(w, "invalid student_id")
		return
	}
	link := ParentStudent{ParentID: pid, StudentID: sid}
	if err := h.db.WithContext(r.Context()).Create(&link).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, link)
}

func (h *Handler) unlink(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	res := h.db.WithContext(r.Context()).Delete(&ParentStudent{}, "id = ?", id)
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
