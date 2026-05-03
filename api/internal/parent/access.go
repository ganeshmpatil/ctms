package parent

import (
	"context"

	"gorm.io/gorm"
)

// StudentIDsForParent returns the IDs of students linked to a parent user.
// Used to row-filter list endpoints and authorise single-record reads.
func StudentIDsForParent(ctx context.Context, db *gorm.DB, parentID string) ([]string, error) {
	var ids []string
	err := db.WithContext(ctx).
		Model(&ParentStudent{}).
		Where("parent_id = ?", parentID).
		Pluck("student_id", &ids).Error
	return ids, err
}

// IsParentOfStudent reports whether the given parent has a link to the given student.
func IsParentOfStudent(ctx context.Context, db *gorm.DB, parentID, studentID string) (bool, error) {
	var count int64
	err := db.WithContext(ctx).
		Model(&ParentStudent{}).
		Where("parent_id = ? AND student_id = ?", parentID, studentID).
		Count(&count).Error
	return count > 0, err
}
