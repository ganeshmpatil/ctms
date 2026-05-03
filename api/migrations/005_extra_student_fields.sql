-- Rename guardian_phone -> mobile_1; add mobile_2, mobile_3, aadhar, school_name, reference.
ALTER TABLE students RENAME COLUMN guardian_phone TO mobile_1;
ALTER TABLE students ADD COLUMN IF NOT EXISTS mobile_2    TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS mobile_3    TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS aadhar      TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS school_name TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS reference   TEXT;
