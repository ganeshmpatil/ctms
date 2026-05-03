# ctms — Class & Teacher Management System

Multi-role school management app: Go API + Postgres + Flutter Android client.

## Stack

| Layer | Tech |
|---|---|
| Mobile client | Flutter (Android) |
| API | Go 1.22, GORM, JWT auth, Casbin RBAC |
| Database | Postgres (Supabase or self-hosted) |
| Distribution | Sideloaded APK + Cloud-hosted API |

## Roles

| Role | Access |
|---|---|
| `admin` | Everything |
| `teacher` | Read divisions/subjects/schools; full CRUD on students/results/attendance |
| `staff` | Read students/divisions/schools; full CRUD on leads |
| `parent` | Read-only access to **their own linked students** (row-level filter) and reference data |

Role-to-endpoint mapping is in [api/internal/rbac/policy.csv](api/internal/rbac/policy.csv); row-level "only my kid" filtering is in [api/internal/parent/access.go](api/internal/parent/access.go).

## Layout

```
api/
├── cmd/api/         # entrypoint
├── internal/
│   ├── auth/        # JWT auth + middleware
│   ├── rbac/        # Casbin enforcer + policy.csv
│   ├── parent/      # parent↔student linkage + row-level filter
│   └── <domain>/    # one folder per entity (students, results, ...)
└── migrations/      # SQL schema + seed
flutter_app/         # Flutter Android client (Gurukul branding)
```

## Local development

### 1. Postgres

```bash
docker run -d --name localpostgres -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres postgres:17

# Apply migrations
psql "postgresql://postgres:postgres@localhost:5432/postgres" \
  -f api/migrations/001_schema.sql \
  -f api/migrations/002_seed.sql \
  -f api/migrations/003_parent.sql
```

### 2. API

Copy [api/.env.example](api/.env.example) to `api/.env` and fill in your `DATABASE_URL` + `JWT_SECRET`. Then:

```bash
cd api
go run ./cmd/api
# Listens on :8080 (or PORT from .env)
```

Smoke test:

```bash
TOKEN=$(curl -s -X POST localhost:8090/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"VijayPatil","password":"Welcome1"}' | jq -r .token)

curl localhost:8090/divisions -H "Authorization: Bearer $TOKEN"
```

### 3. Flutter app

```bash
cd flutter_app
flutter pub get
flutter run --dart-define=API_BASE=http://<your-lan-ip>:8090
```

## Default users (seeded)

| Email | Password | Role |
|---|---|---|
| `VijayPatil` | `Welcome1` | admin |
| `admin@school.local` | `admin123` | admin |

## Build a release APK

```bash
./build-apk.sh https://<your-deployed-api-url>
# outputs dist/app-release.apk
```
