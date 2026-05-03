package subject

import (
	"net/http"

	"gorm.io/gorm"

	"school-api/internal/httpx"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /subjects", h.list)
	mux.HandleFunc("POST /subjects", h.create)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]Subject, 0)
	if err := h.db.WithContext(r.Context()).Order("description").Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var s Subject
	if err := httpx.DecodeJSON(r, &s); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if s.Description == "" {
		httpx.BadRequest(w, "description required")
		return
	}
	if err := h.db.WithContext(r.Context()).Create(&s).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, s)
}
