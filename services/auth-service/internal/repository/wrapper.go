package repository

import "context"

// Helper to close repository pool when previously created via NewRepository
func NewRepository(ctx context.Context, dsn string) *Repository {
	// this function wraps the earlier NewRepository to keep compatibility with main.go wiring
	r, err := NewRepository(ctx, dsn)
	if err != nil {
		panic(err)
	}
	return r
}
