-- Allow 'parent' role
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('admin', 'teacher', 'staff', 'parent'));

-- Extend users to a full "human" registry
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name  TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone      TEXT;

-- Parent ↔ Student linkage. A parent can be linked to multiple students;
-- a student can have multiple guardians (parent_a, parent_b, etc.).
CREATE TABLE IF NOT EXISTS parent_students (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id   UUID NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (parent_id, student_id)
);
CREATE INDEX IF NOT EXISTS parent_students_parent_idx  ON parent_students (parent_id);
CREATE INDEX IF NOT EXISTS parent_students_student_idx ON parent_students (student_id);

-- Default admin requested by stakeholder
INSERT INTO users (email, first_name, last_name, password_hash, role)
VALUES ('VijayPatil', 'Vijay', 'Patil', crypt('Welcome1', gen_salt('bf')), 'admin')
ON CONFLICT (email) DO NOTHING;
