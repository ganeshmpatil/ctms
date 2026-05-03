package lead

import (
	"time"

	"github.com/google/uuid"
)

type Lead struct {
	ID                        uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	Query                     string    `gorm:"not null"                                       json:"query"`
	LeadRaisedBy              *string   `                                                      json:"lead_raised_by,omitempty"`
	LeadRaisedByContactNumber *string   `                                                      json:"lead_raised_by_contact_number,omitempty"`
	Status                    string    `gorm:"not null;default:open"                          json:"status"`
	IsResolved                bool      `gorm:"not null;default:false"                         json:"is_resolved"`
	Comments                  *string   `                                                      json:"comments,omitempty"`
	CreatedAt                 time.Time `                                                      json:"created_at"`
	UpdatedAt                 time.Time `                                                      json:"updated_at"`
}

func (Lead) TableName() string { return "leads" }
