package student

import (
	"time"

	"github.com/google/uuid"
)

type Student struct {
	ID         uuid.UUID  `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Name       string     `gorm:"not null"                                       json:"name"`
	Address    *string    `                                                      json:"address,omitempty"`
	DivisionID *uuid.UUID `gorm:"type:uuid"                                      json:"division_id"`
	Mobile1    *string    `gorm:"column:mobile_1"                                json:"mobile_1,omitempty"`
	Mobile2    *string    `gorm:"column:mobile_2"                                json:"mobile_2,omitempty"`
	Mobile3    *string    `gorm:"column:mobile_3"                                json:"mobile_3,omitempty"`
	Photo      *string    `gorm:"column:photo"                                   json:"photo,omitempty"`
	SchoolID   *uuid.UUID `gorm:"type:uuid"                                      json:"school_id,omitempty"`
	SchoolName *string    `gorm:"column:school_name"                             json:"school_name,omitempty"`
	Aadhar     *string    `                                                      json:"aadhar,omitempty"`
	Reference  *string    `                                                      json:"reference,omitempty"`
	DOB        *time.Time `gorm:"type:date;column:dob"                           json:"dob,omitempty"`
	Gender     *string    `                                                      json:"gender,omitempty"`
	CreatedAt  time.Time  `                                                      json:"created_at"`
}

func (Student) TableName() string { return "students" }
