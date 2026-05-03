package auth

import (
	"net/http"
	"strings"

	"school-api/internal/httpx"
)

// Middleware extracts and validates a JWT, attaches Identity to the context.
// `skip` returns true for paths that bypass authentication (e.g. /healthz, /auth/*).
func Middleware(skip func(path string) bool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if skip != nil && skip(r.URL.Path) {
				next.ServeHTTP(w, r)
				return
			}
			authz := r.Header.Get("Authorization")
			if !strings.HasPrefix(authz, "Bearer ") {
				httpx.WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": "missing bearer token"})
				return
			}
			claims, err := ParseJWT(strings.TrimPrefix(authz, "Bearer "))
			if err != nil {
				httpx.WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": "invalid token: " + err.Error()})
				return
			}
			ctx := WithIdentity(r.Context(), &Identity{
				ID:    claims.UserID.String(),
				Email: claims.Email,
				Role:  claims.Role,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
