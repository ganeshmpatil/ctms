package auth

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID           uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Email        string    `gorm:"not null;unique"                                json:"email"`
	PasswordHash string    `gorm:"column:password_hash;not null"                  json:"-"`
	Role         string    `gorm:"not null"                                       json:"role"`
	FirstName    *string   `gorm:"column:first_name"                              json:"first_name,omitempty"`
	LastName     *string   `gorm:"column:last_name"                               json:"last_name,omitempty"`
	Phone        *string   `                                                      json:"phone,omitempty"`
	CreatedAt    time.Time `                                                      json:"created_at"`
}

func (User) TableName() string { return "users" }
