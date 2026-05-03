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
	mux.HandleFunc("PATCH /divisions/{id}", h.update)
	mux.HandleFunc("DELETE /divisions/{id}", h.delete)
	mux.HandleFunc("POST /divisions/{id}/reset", h.reset)
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

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var patch struct {
		Standard *int    `json:"standard"`
		Medium   *string `json:"medium"`
	}
	if err := httpx.DecodeJSON(r, &patch); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}

	updates := map[string]any{}
	if patch.Standard != nil {
		if *patch.Standard < 1 || *patch.Standard > 12 {
			httpx.BadRequest(w, "standard must be 1..12")
			return
		}
		updates["standard"] = *patch.Standard
	}
	if patch.Medium != nil {
		if *patch.Medium != "english" && *patch.Medium != "marathi" {
			httpx.BadRequest(w, "medium must be 'english' or 'marathi'")
			return
		}
		updates["medium"] = *patch.Medium
	}

	var d Division
	tx := h.db.WithContext(r.Context())
	if err := tx.First(&d, "id = ?", id).Error; err != nil {
		if httpx.IsNotFound(err) {
			httpx.NotFound(w)
			return
		}
		httpx.ServerError(w, err)
		return
	}
	if len(updates) > 0 {
		if err := tx.Model(&d).Updates(updates).Error; err != nil {
			httpx.ServerError(w, err)
			return
		}
	}
	httpx.WriteJSON(w, http.StatusOK, d)
}

// delete refuses if any students are linked to this division.
func (h *Handler) delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var count int64
	if err := h.db.WithContext(r.Context()).
		Table("students").
		Where("division_id = ?", id).
		Count(&count).Error; err != nil {
		httpx.ServerError(w, err)
		return
	}
	if count > 0 {
		httpx.WriteJSON(w, http.StatusConflict, map[string]any{
			"error":    "division has students; reassign or run year-end reset first",
			"students": count,
		})
		return
	}
	tx := h.db.WithContext(r.Context()).Delete(&Division{}, "id = ?", id)
	if tx.Error != nil {
		httpx.ServerError(w, tx.Error)
		return
	}
	if tx.RowsAffected == 0 {
		httpx.NotFound(w)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// reset performs a year-end reset on a division:
//   - DELETE all attendance and results for students currently linked to this division
//   - SET division_id = NULL on those students (students themselves are preserved)
//
// Body must include {"confirm": true} or the request is refused.
func (h *Handler) reset(w http.ResponseWriter, r *http.Request) {
	divisionID := r.PathValue("id")

	var body struct {
		Confirm bool `json:"confirm"`
	}
	if err := httpx.DecodeJSON(r, &body); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if !body.Confirm {
		httpx.BadRequest(w, "destructive operation; pass {\"confirm\": true}")
		return
	}

	type counts struct {
		Students   int64 `json:"students_unassigned"`
		Attendance int64 `json:"attendance_deleted"`
		Results    int64 `json:"results_deleted"`
	}
	var c counts

	err := h.db.WithContext(r.Context()).Transaction(func(tx *gorm.DB) error {
		// Snapshot the student IDs in this division.
		var sids []string
		if err := tx.Table("students").
			Where("division_id = ?", divisionID).
			Pluck("id", &sids).Error; err != nil {
			return err
		}
		if len(sids) == 0 {
			return nil
		}

		att := tx.Exec("DELETE FROM attendance WHERE student_id IN ?", sids)
		if att.Error != nil {
			return att.Error
		}
		c.Attendance = att.RowsAffected

		// Delete results (cascade to result_subjects via FK)
		res := tx.Exec("DELETE FROM results WHERE student_id IN ?", sids)
		if res.Error != nil {
			return res.Error
		}
		c.Results = res.RowsAffected

		stu := tx.Exec("UPDATE students SET division_id = NULL WHERE division_id = ?", divisionID)
		if stu.Error != nil {
			return stu.Error
		}
		c.Students = stu.RowsAffected
		return nil
	})
	if err != nil {
		httpx.ServerError(w, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, c)
}
