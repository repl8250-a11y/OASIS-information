package repository

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository wraps DB connections and prepared statements
type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(ctx context.Context, dsn string) (*Repository, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, err
	}
	// simple ping
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return &Repository{db: pool}, nil
}

func (r *Repository) Close() {
	r.db.Close()
}

// User represents the canonical user profile stored in DB
type User struct {
	ID        string
	Email     string
	Password  string // stored as salt$hash
	Disabled  bool
	CreatedAt time.Time
	UpdatedAt sql.NullTime
	DeletedAt sql.NullTime
	Version   int
}

var ErrNotFound = errors.New("not found")

// GetUserByEmail returns a user by canonicalized email
func (r *Repository) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	row := r.db.QueryRow(ctx, `SELECT id, email, password_hash, disabled, created_at, updated_at, deleted_at, version FROM users WHERE email = lower($1) AND deleted_at IS NULL`, email)
	u := &User{}
	var updatedAt, deletedAt sql.NullTime
	if err := row.Scan(&u.ID, &u.Email, &u.Password, &u.Disabled, &u.CreatedAt, &updatedAt, &deletedAt, &u.Version); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	u.UpdatedAt = updatedAt
	u.DeletedAt = deletedAt
	return u, nil
}

// CreateUser inserts a new user. Email is stored lowercased; version starts at 1.
func (r *Repository) CreateUser(ctx context.Context, email, passwordHash string) (*User, error) {
	var id string
	row := r.db.QueryRow(ctx, `INSERT INTO users (email, password_hash) VALUES (lower($1), $2) RETURNING id, created_at`, email, passwordHash)
	u := &User{Email: email, Password: passwordHash}
	if err := row.Scan(&id, &u.CreatedAt); err != nil {
		return nil, err
	}
	u.ID = id
	u.Version = 1
	return u, nil
}

// StoreRefreshToken stores a refresh token hashed, linked to user
func (r *Repository) StoreRefreshToken(ctx context.Context, userID, token string, expiresAt time.Time) (string, error) {
	hash := hashToken(token)
	var id string
	row := r.db.QueryRow(ctx, `INSERT INTO refresh_tokens (user_id, token_hash, issued_at, expires_at) VALUES ($1, $2, now(), $3) RETURNING id`, userID, hash, expiresAt)
	if err := row.Scan(&id); err != nil {
		return "", err
	}
	return id, nil
}

// RotateRefreshToken revokes the old token and inserts new one in a transaction
func (r *Repository) RotateRefreshToken(ctx context.Context, oldToken, newToken, userID string, newExpires time.Time) (string, error) {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	oldHash := hashToken(oldToken)
	// revoke old
	if _, err := tx.Exec(ctx, `UPDATE refresh_tokens SET revoked = true WHERE token_hash = $1`, oldHash); err != nil {
		return "", err
	}

	newHash := hashToken(newToken)
	var id string
	row := tx.QueryRow(ctx, `INSERT INTO refresh_tokens (user_id, token_hash, issued_at, expires_at) VALUES ($1, $2, now(), $3) RETURNING id`, userID, newHash, newExpires)
	if err := row.Scan(&id); err != nil {
		return "", err
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

func (r *Repository) RevokeRefreshToken(ctx context.Context, token string) error {
	hash := hashToken(token)
	res, err := r.db.Exec(ctx, `UPDATE refresh_tokens SET revoked = true WHERE token_hash = $1`, hash)
	if err != nil {
		return err
	}
	if res.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func hashToken(token string) string {
	h := sha256.Sum256([]byte(token))
	return hex.EncodeToString(h[:])
}
