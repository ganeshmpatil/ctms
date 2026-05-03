package auth

import "context"

type ctxKey struct{}

type Identity struct {
	ID    string
	Email string
	Role  string
}

func WithIdentity(ctx context.Context, id *Identity) context.Context {
	return context.WithValue(ctx, ctxKey{}, id)
}

func IdentityFromCtx(ctx context.Context) *Identity {
	id, _ := ctx.Value(ctxKey{}).(*Identity)
	return id
}
