package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/joho/godotenv"

	"school-api/internal/attendance"
	"school-api/internal/auth"
	"school-api/internal/db"
	"school-api/internal/division"
	"school-api/internal/lead"
	"school-api/internal/parent"
	"school-api/internal/rbac"
	"school-api/internal/result"
	"school-api/internal/school"
	"school-api/internal/student"
	"school-api/internal/subject"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Printf("no .env loaded (%v) — relying on shell environment", err)
	}

	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL not set")
	}

	ctx := context.Background()
	gdb, err := db.New(ctx, dsn)
	if err != nil {
		log.Fatalf("db: %v", err)
	}

	enforcer, err := rbac.New()
	if err != nil {
		log.Fatalf("rbac: %v", err)
	}

	mux := http.NewServeMux()

	// Public — bypass both auth and rbac.
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	})
	auth.RegisterRoutes(mux, gdb)

	// Protected — every request runs auth.Middleware → rbac.Middleware.
	school.RegisterRoutes(mux, gdb)
	division.RegisterRoutes(mux, gdb)
	subject.RegisterRoutes(mux, gdb)
	student.RegisterRoutes(mux, gdb)
	result.RegisterRoutes(mux, gdb)
	attendance.RegisterRoutes(mux, gdb)
	lead.RegisterRoutes(mux, gdb)
	parent.RegisterRoutes(mux, gdb)

	skip := func(path string) bool {
		return path == "/healthz" || strings.HasPrefix(path, "/auth/")
	}

	handler := withCORS(auth.Middleware(skip)(enforcer.Middleware(skip)(mux)))

	addr := ":" + firstNonEmpty(os.Getenv("PORT"), "8080")
	log.Printf("listening on %s", addr)
	srv := &http.Server{
		Addr:              addr,
		Handler:           withLogging(handler),
		ReadHeaderTimeout: 5 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}

func withCORS(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Max-Age", "86400")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		h.ServeHTTP(w, r)
	})
}

func firstNonEmpty(a, b string) string {
	if a != "" {
		return a
	}
	return b
}

func withLogging(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		h.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(start))
	})
}
