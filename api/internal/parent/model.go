package parent

import (
	"time"

	"github.com/google/uuid"
)

type ParentStudent struct {
	ID        uuid.UUID `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	ParentID  uuid.UUID `gorm:"type:uuid;not null;column:parent_id"            json:"parent_id"`
	StudentID uuid.UUID `gorm:"type:uuid;not null;column:student_id"           json:"student_id"`
	CreatedAt time.Time `                                                      json:"created_at"`
}

func (ParentStudent) TableName() string { return "parent_students" }
