package school

import (
	"time"

	"github.com/google/uuid"
)

type School struct {
	ID        uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Name      string    `gorm:"not null"                                       json:"name"`
	Address   *string   `                                                      json:"address,omitempty"`
	CreatedAt time.Time `                                                      json:"created_at"`
}

func (School) TableName() string { return "schools" }
