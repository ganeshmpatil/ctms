package student

import (
	"time"

	"github.com/google/uuid"
)

type Student struct {
	ID            uuid.UUID  `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Name          string     `gorm:"not null"                                       json:"name"`
	Address       *string    `                                                      json:"address,omitempty"`
	DivisionID    uuid.UUID  `gorm:"type:uuid;not null"                             json:"division_id"`
	GuardianPhone *string    `                                                      json:"guardian_phone,omitempty"`
	PhotoURL      *string    `                                                      json:"photo_url,omitempty"`
	SchoolID      *uuid.UUID `gorm:"type:uuid"                                      json:"school_id,omitempty"`
	CreatedAt     time.Time  `                                                      json:"created_at"`
}

func (Student) TableName() string { return "students" }
