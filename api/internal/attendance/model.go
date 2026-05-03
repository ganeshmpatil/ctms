package attendance

import (
	"time"

	"github.com/google/uuid"
)

type Attendance struct {
	ID           uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	StudentID    uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:ux_student_date" json:"student_id"`
	Date         time.Time `gorm:"type:date;not null;uniqueIndex:ux_student_date" json:"date"`
	IsPresent    bool      `gorm:"not null"                                       json:"is_present"`
	IsAbsent     bool      `gorm:"not null"                                       json:"is_absent"`
	AbsentReason *string   `                                                      json:"absent_reason,omitempty"`
}

func (Attendance) TableName() string { return "attendance" }
