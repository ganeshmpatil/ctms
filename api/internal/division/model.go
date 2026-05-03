package division

import "github.com/google/uuid"

type Division struct {
	ID       uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Standard int       `gorm:"not null"                                       json:"standard"`
	Medium   string    `gorm:"not null"                                       json:"medium"`
}

func (Division) TableName() string { return "divisions" }
