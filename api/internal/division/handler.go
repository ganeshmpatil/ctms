package division

import (
	"net/http"

	"gorm.io/gorm"

	"school-api/internal/httpx"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /divisions", h.list)
	mux.HandleFunc("POST /divisions", h.create)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]Division, 0)
	if err := h.db.WithContext(r.Context()).Order("standard, medium").Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var d Division
	if err := httpx.DecodeJSON(r, &d); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if d.Standard < 1 || d.Standard > 12 {
		httpx.BadRequest(w, "standard must be 1..12")
		return
	}
	if d.Medium != "english" && d.Medium != "marathi" {
		httpx.BadRequest(w, "medium must be 'english' or 'marathi'")
		return
	}
	if err := h.db.WithContext(r.Context()).Create(&d).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, d)
}
