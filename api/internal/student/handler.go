package student

import (
	"net/http"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"school-api/internal/auth"
	"school-api/internal/httpx"
	"school-api/internal/parent"
)

type Handler struct{ db *gorm.DB }

func RegisterRoutes(mux *http.ServeMux, db *gorm.DB) {
	h := &Handler{db: db}
	mux.HandleFunc("GET /students", h.list)
	mux.HandleFunc("POST /students", h.create)
	mux.HandleFunc("GET /students/{id}", h.get)
	mux.HandleFunc("PATCH /students/{id}", h.update)
	mux.HandleFunc("DELETE /students/{id}", h.delete)
}

// list returns all students. For parents, only their linked children.
// `division_id=` filters by division. `division_id=null` returns unassigned students.
func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	out := make([]Student, 0)
	q := h.db.WithContext(r.Context()).Order("created_at DESC")

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
		q = q.Where("id IN ?", ids)
	} else if div := r.URL.Query().Get("division_id"); div != "" {
		if div == "null" {
			q = q.Where("division_id IS NULL")
		} else {
			q = q.Where("division_id = ?", div)
		}
	}

	if err := q.Find(&out).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	studentID := r.PathValue("id")

	id := auth.IdentityFromCtx(r.Context())
	if id != nil && id.Role == "parent" {
		ok, err := parent.IsParentOfStudent(r.Context(), h.db, id.ID, studentID)
		if err != nil {
			httpx.ServerError(w, err)
			return
		}
		if !ok {
			httpx.WriteJSON(w, http.StatusForbidden,
				map[string]string{"error": "this student is not linked to your account"})
			return
		}
	}

	var s Student
	err := h.db.WithContext(r.Context()).First(&s, "id = ?", studentID).Error
	if httpx.IsNotFound(err) {
		httpx.NotFound(w)
		return
	}
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, s)
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	req, err := decodeRequest(r)
	if err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if req.Name == nil || *req.Name == "" || req.DivisionID == nil {
		httpx.BadRequest(w, "name and division_id required")
		return
	}
	s := Student{
		Name:          *req.Name,
		Address:       req.Address,
		GuardianPhone: req.GuardianPhone,
		Photo:         req.Photo,
		Gender:        req.Gender,
		DOB:           req.DOB,
	}
	if did, err := uuid.Parse(*req.DivisionID); err == nil {
		s.DivisionID = &did
	} else {
		httpx.BadRequest(w, "invalid division_id")
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
	req, err := decodeRequest(r)
	if err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}

	updates := map[string]any{}
	if req.Name != nil {
		updates["name"] = *req.Name
	}
	if req.Address != nil {
		updates["address"] = *req.Address
	}
	if req.DivisionID != nil {
		div, err := uuid.Parse(*req.DivisionID)
		if err != nil {
			httpx.BadRequest(w, "invalid division_id")
			return
		}
		updates["division_id"] = div
	}
	if req.GuardianPhone != nil {
		updates["guardian_phone"] = *req.GuardianPhone
	}
	if req.Photo != nil {
		updates["photo"] = *req.Photo
	}
	if req.Gender != nil {
		updates["gender"] = *req.Gender
	}
	if req.DOB != nil {
		updates["dob"] = *req.DOB
	}

	var s Student
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

func (h *Handler) delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	res := h.db.WithContext(r.Context()).Delete(&Student{}, "id = ?", id)
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

// studentRequest captures both create and update payloads. All fields optional;
// caller validates which are required.
type studentRequest struct {
	Name          *string    `json:"name"`
	Address       *string    `json:"address"`
	DivisionID    *string    `json:"division_id"`
	GuardianPhone *string    `json:"guardian_phone"`
	Photo         *string    `json:"photo"`
	SchoolID      *string    `json:"school_id"`
	Gender        *string    `json:"gender"`
	DOB           *time.Time `json:"-"`
	DOBStr        *string    `json:"dob"`
}

func decodeRequest(r *http.Request) (*studentRequest, error) {
	var req studentRequest
	if err := httpx.DecodeJSON(r, &req); err != nil {
		return nil, err
	}
	if req.DOBStr != nil && *req.DOBStr != "" {
		t, err := parseDate(*req.DOBStr)
		if err != nil {
			return nil, err
		}
		req.DOB = &t
	}
	return &req, nil
}

// parseDate accepts YYYY-MM-DD or full RFC3339 (matches attendance handler).
func parseDate(s string) (time.Time, error) {
	if t, err := time.Parse("2006-01-02", s); err == nil {
		return t, nil
	}
	return time.Parse(time.RFC3339, s)
}
