CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Application users (for auth). Distinct from "students" entity below.
CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role          TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'staff')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS schools (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    address     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS divisions (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    standard  INT  NOT NULL CHECK (standard BETWEEN 1 AND 12),
    medium    TEXT NOT NULL CHECK (medium IN ('english', 'marathi')),
    UNIQUE (standard, medium)
);

CREATE TABLE IF NOT EXISTS subjects (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    description  TEXT NOT NULL UNIQUE,
    is_english   BOOLEAN NOT NULL DEFAULT FALSE,
    is_hindi     BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS students (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    address         TEXT,
    division_id     UUID NOT NULL REFERENCES divisions(id),
    guardian_phone  TEXT,
    photo_url       TEXT,
    school_id       UUID REFERENCES schools(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS students_division_idx ON students (division_id);

CREATE TABLE IF NOT EXISTS results (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id   UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    year         INT  NOT NULL,
    month        INT  NOT NULL CHECK (month BETWEEN 1 AND 12),
    total_marks  NUMERIC(8,2),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, year, month)
);

CREATE TABLE IF NOT EXISTS result_subjects (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    result_id      UUID NOT NULL REFERENCES results(id) ON DELETE CASCADE,
    subject_id     UUID NOT NULL REFERENCES subjects(id),
    marks          NUMERIC(6,2) NOT NULL,
    out_of_marks   NUMERIC(6,2) NOT NULL,
    UNIQUE (result_id, subject_id)
);

CREATE TABLE IF NOT EXISTS attendance (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id     UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    date           DATE NOT NULL,
    is_present     BOOLEAN NOT NULL DEFAULT FALSE,
    is_absent      BOOLEAN NOT NULL DEFAULT FALSE,
    absent_reason  TEXT,
    UNIQUE (student_id, date),
    CHECK (is_present <> is_absent)
);
CREATE INDEX IF NOT EXISTS attendance_date_idx ON attendance (date);

CREATE TABLE IF NOT EXISTS leads (
    id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query                         TEXT NOT NULL,
    lead_raised_by                TEXT,
    lead_raised_by_contact_number TEXT,
    status                        TEXT NOT NULL DEFAULT 'open',
    is_resolved                   BOOLEAN NOT NULL DEFAULT FALSE,
    comments                      TEXT,
    created_at                    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS leads_status_idx ON leads (status);
