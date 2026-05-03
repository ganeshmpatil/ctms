package result

import (
	"time"

	"github.com/google/uuid"
)

type Result struct {
	ID         uuid.UUID       `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	StudentID  uuid.UUID       `gorm:"type:uuid;not null"                             json:"student_id"`
	Year       int             `gorm:"not null"                                       json:"year"`
	Month      int             `gorm:"not null"                                       json:"month"`
	TotalMarks *float64        `gorm:"column:total_marks"                             json:"total_marks,omitempty"`
	Photo      *string         `gorm:"column:photo"                                   json:"photo,omitempty"`
	CreatedAt  time.Time       `                                                      json:"created_at"`
	Subjects   []ResultSubject `gorm:"foreignKey:ResultID;constraint:OnDelete:CASCADE" json:"subjects"`
}

func (Result) TableName() string { return "results" }

type ResultSubject struct {
	ID         uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id,omitempty"`
	ResultID   uuid.UUID `gorm:"type:uuid;not null"                             json:"-"`
	SubjectID  uuid.UUID `gorm:"type:uuid;not null"                             json:"subject_id"`
	Marks      float64   `gorm:"not null"                                       json:"marks"`
	OutOfMarks float64   `gorm:"column:out_of_marks;not null"                   json:"out_of_marks"`
}

func (ResultSubject) TableName() string { return "result_subjects" }
