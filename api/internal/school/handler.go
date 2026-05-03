package school

import (
	"net/http"

	"gorm.io/gorm"

	"school-api/internal/httpx"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /schools", h.list)
	mux.HandleFunc("POST /schools", h.create)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]School, 0)
	if err := h.db.WithContext(r.Context()).Order("created_at DESC").Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var s School
	if err := httpx.DecodeJSON(r, &s); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if s.Name == "" {
		httpx.BadRequest(w, "name required")
		return
	}
	if err := h.db.WithContext(r.Context()).Create(&s).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, s)
}
