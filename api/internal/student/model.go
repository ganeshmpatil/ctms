package student

import (
	"time"

	"github.com/google/uuid"
)

type Student struct {
	ID            uuid.UUID  `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Name          string     `gorm:"not null"                                       json:"name"`
	Address       *string    `                                                      json:"address,omitempty"`
	DivisionID    *uuid.UUID `gorm:"type:uuid"                                      json:"division_id"`
	GuardianPhone *string    `gorm:"column:guardian_phone"                          json:"guardian_phone,omitempty"`
	Photo         *string    `gorm:"column:photo"                                   json:"photo,omitempty"`
	SchoolID      *uuid.UUID `gorm:"type:uuid"                                      json:"school_id,omitempty"`
	DOB           *time.Time `gorm:"type:date;column:dob"                           json:"dob,omitempty"`
	Gender        *string    `                                                      json:"gender,omitempty"`
	CreatedAt     time.Time  `                                                      json:"created_at"`
}

func (Student) TableName() string { return "students" }
