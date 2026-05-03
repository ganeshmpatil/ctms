package rbac

import (
	_ "embed"
	"net/http"
	"os"
	"path/filepath"

	"github.com/casbin/casbin/v2"
	"github.com/casbin/casbin/v2/model"
	fileadapter "github.com/casbin/casbin/v2/persist/file-adapter"

	"school-api/internal/auth"
	"school-api/internal/httpx"
)

//go:embed model.conf
var modelText string

//go:embed policy.csv
var policyData []byte

type Enforcer struct{ e *casbin.Enforcer }

func New() (*Enforcer, error) {
	m, err := model.NewModelFromString(modelText)
	if err != nil {
		return nil, err
	}
	tmp := filepath.Join(os.TempDir(), "school-api-policy.csv")
	if err := os.WriteFile(tmp, policyData, 0o600); err != nil {
		return nil, err
	}
	a := fileadapter.NewAdapter(tmp)
	e, err := casbin.NewEnforcer(m, a)
	if err != nil {
		return nil, err
	}
	return &Enforcer{e: e}, nil
}

// Middleware enforces RBAC after the auth middleware has populated the identity.
// `skip` returns true for paths that bypass authorization (must match auth.Middleware's skip).
func (en *Enforcer) Middleware(skip func(path string) bool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if skip != nil && skip(r.URL.Path) {
				next.ServeHTTP(w, r)
				return
			}
			id := auth.IdentityFromCtx(r.Context())
			if id == nil {
				httpx.WriteJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthenticated"})
				return
			}
			ok, err := en.e.Enforce(id.Role, r.URL.Path, r.Method)
			if err != nil {
				httpx.ServerError(w, err)
				return
			}
			if !ok {
				httpx.WriteJSON(w, http.StatusForbidden,
					map[string]string{"error": "role '" + id.Role + "' is not allowed to " + r.Method + " " + r.URL.Path})
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
