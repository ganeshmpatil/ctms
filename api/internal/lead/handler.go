package lead

import (
	"net/http"

	"gorm.io/gorm"

	"school-api/internal/httpx"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /leads", h.list)
	mux.HandleFunc("POST /leads", h.create)
	mux.HandleFunc("PATCH /leads/{id}", h.update)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]Lead, 0)
	q := h.db.WithContext(r.Context()).Order("created_at DESC")
	if status := r.URL.Query().Get("status"); status != "" {
		q = q.Where("status = ?", status)
	}
	if err := q.Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Query                     string  `json:"query"`
		LeadRaisedBy              *string `json:"lead_raised_by"`
		LeadRaisedByContactNumber *string `json:"lead_raised_by_contact_number"`
		Comments                  *string `json:"comments"`
	}
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if req.Query == "" {
		httpx.BadRequest(w, "query required")
		return
	}
	l := Lead{
		Query:                     req.Query,
		LeadRaisedBy:              req.LeadRaisedBy,
		LeadRaisedByContactNumber: req.LeadRaisedByContactNumber,
		Status:                    "open",
		Comments:                  req.Comments,
	}
	if err := h.db.WithContext(r.Context()).Create(&l).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, l)
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var patch struct {
		Status     *string `json:"status"`
		IsResolved *bool   `json:"is_resolved"`
		Comments   *string `json:"comments"`
	}
	if err := httpx.DecodeJSON(r, &patch); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}

	updates := map[string]any{}
	if patch.Status != nil {
		updates["status"] = *patch.Status
	}
	if patch.IsResolved != nil {
		updates["is_resolved"] = *patch.IsResolved
	}
	if patch.Comments != nil {
		updates["comments"] = *patch.Comments
	}

	var l Lead
	tx := h.db.WithContext(r.Context())
	if err := tx.First(&l, "id = ?", id).Error; err != nil {
		if httpx.IsNotFound(err) {
			httpx.NotFound(w)
			return
		}
		httpx.ServerError(w, err)
		return
	}
	if len(updates) > 0 {
		if err := tx.Model(&l).Updates(updates).Error; err != nil {
			httpx.ServerError(w, err)
			return
		}
	}
	httpx.WriteJSON(w, http.StatusOK, l)
}
