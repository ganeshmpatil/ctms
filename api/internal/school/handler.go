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
	mux.HandleFunc("PATCH /schools/{id}", h.update)
	mux.HandleFunc("DELETE /schools/{id}", h.delete)
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

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var patch struct {
		Name    *string `json:"name"`
		Address *string `json:"address"`
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

	var s School
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

// delete refuses if any students reference this school.
func (h *Handler) delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var count int64
	if err := h.db.WithContext(r.Context()).
		Table("students").
		Where("school_id = ?", id).
		Count(&count).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	if count > 0 {
		httpx.WriteJSON(w, http.StatusConflict, map[string]any{
			"error":    "school has students; reassign or remove them first",
			"students": count,
		})
		return
	}
	res := h.db.WithContext(r.Context()).Delete(&School{}, "id = ?", id)
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
