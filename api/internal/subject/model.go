package subject

import "github.com/google/uuid"

type Subject struct {
	ID          uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Description string    `gorm:"not null;unique"                                json:"description"`
	IsEnglish   bool      `                                                      json:"is_english"`
	IsHindi     bool      `                                                      json:"is_hindi"`
}

func (Subject) TableName() string { return "subjects" }
