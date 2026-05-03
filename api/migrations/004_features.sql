-- New student fields: photo (base64), date of birth, gender.
ALTER TABLE students RENAME COLUMN photo_url TO photo;
ALTER TABLE students ADD COLUMN IF NOT EXISTS dob    DATE;
ALTER TABLE students ADD COLUMN IF NOT EXISTS gender TEXT
    CHECK (gender IN ('male', 'female', 'other'));

-- Allow division_id to be NULL so year-end reset can unassign students.
ALTER TABLE students ALTER COLUMN division_id DROP NOT NULL;

-- Result attachment: photo of marksheet etc.
ALTER TABLE results ADD COLUMN IF NOT EXISTS photo TEXT;
