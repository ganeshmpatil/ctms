-- Idempotent seed: admin user, divisions 1..10 in both mediums, base subjects, one demo student.

-- Default admin (password: admin123). Rotate on first login.
INSERT INTO users (email, password_hash, role)
VALUES ('admin@school.local', crypt('admin123', gen_salt('bf')), 'admin')
ON CONFLICT (email) DO NOTHING;


INSERT INTO divisions (standard, medium)
SELECT s, m
FROM generate_series(1, 10) AS s
CROSS JOIN (VALUES ('english'), ('marathi')) AS x(m)
ON CONFLICT (standard, medium) DO NOTHING;

INSERT INTO subjects (description, is_english, is_hindi) VALUES
    ('Maths',     FALSE, FALSE),
    ('Science',   FALSE, FALSE),
    ('History',   FALSE, FALSE),
    ('Geography', FALSE, FALSE),
    ('Marathi',   FALSE, FALSE),
    ('English',   TRUE,  FALSE),
    ('Hindi',     FALSE, TRUE)
ON CONFLICT (description) DO NOTHING;

INSERT INTO students (name, division_id, guardian_phone)
SELECT 'John Doe', d.id, '+91-9000000000'
FROM divisions d
WHERE d.standard = 5 AND d.medium = 'english'
  AND NOT EXISTS (SELECT 1 FROM students WHERE name = 'John Doe' AND division_id = d.id);
