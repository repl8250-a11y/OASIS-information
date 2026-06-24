package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/auth"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/repository"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/security"
)

// Request/Response DTOs
type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type tokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

// Handler dependencies
type Handlers struct {
	Repo       *repository.Repository
	PrivateKey *rsaPrivateHolder
	PublicKey  *rsaPublicHolder
	Issuer     string
}

// We hide RSA types to avoid importing crypto/rsa in this package for testability
type rsaPrivateHolder struct{ priv interface{} }
type rsaPublicHolder struct{ pub interface{} }

func NewHandlers(repo *repository.Repository, priv interface{}, pub interface{}, issuer string) *Handlers {
	return &Handlers{Repo: repo, PrivateKey: &rsaPrivateHolder{priv: priv}, PublicKey: &rsaPublicHolder{pub: pub}, Issuer: issuer}
}

// Login handles POST /api/v1/auth/login
func (h *Handlers) Login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Warn().Err(err).Msg("invalid login payload")
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	user, err := h.Repo.GetUserByEmail(r.Context(), req.Email)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "invalid credentials", http.StatusUnauthorized)
			return
		}
		log.Error().Err(err).Msg("db error get user")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	ok, err := security.VerifyPassword(user.Password, req.Password)
	if err != nil || !ok {
		http.Error(w, "invalid credentials", http.StatusUnauthorized)
		return
	}
	// issue tokens
	// generate refresh token
	refreshToken := uuid.NewString()
	expiresAt := time.Now().Add(30 * 24 * time.Hour)
	if _, err := h.Repo.StoreRefreshToken(r.Context(), user.ID, refreshToken, expiresAt); err != nil {
		log.Error().Err(err).Msg("failed to store refresh token")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	// sign access token
	privKey := h.PrivateKey.priv.(*rsa.PrivateKey)
	accessToken, err := auth.SignAccessToken(privKey, user.ID, user.Email, nil, time.Hour, h.Issuer)
	if err != nil {
		log.Error().Err(err).Msg("failed to sign access token")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	resp := tokenResponse{AccessToken: accessToken, RefreshToken: refreshToken, ExpiresIn: 3600}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(resp)
}

// Refresh handles POST /api/v1/auth/refresh
type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *Handlers) Refresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	// For security, in production you'd verify existence and not-returned old token, implement rotation
	// Here we load the user by token hash and rotate
	// This repository method is implemented to perform rotation safely
	// Find user_id via token
	// For brevity we perform a minimal flow
	userID := "" // lookup omitted for brevity - must be implemented in repo
	if userID == "" {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}
	newRefresh := uuid.NewString()
	newExpires := time.Now().Add(30 * 24 * time.Hour)
	if _, err := h.Repo.RotateRefreshToken(r.Context(), req.RefreshToken, newRefresh, userID, newExpires); err != nil {
		log.Error().Err(err).Msg("rotate token failed")
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}
	privKey := h.PrivateKey.priv.(*rsa.PrivateKey)
	accessToken, err := auth.SignAccessToken(privKey, userID, "", nil, time.Hour, h.Issuer)
	if err != nil {
		log.Error().Err(err).Msg("sign access token failed")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	resp := tokenResponse{AccessToken: accessToken, RefreshToken: newRefresh, ExpiresIn: 3600}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(resp)
}

// Logout handles POST /api/v1/auth/logout
func (h *Handlers) Logout(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	if err := h.Repo.RevokeRefreshToken(r.Context(), req.RefreshToken); err != nil {
		if err == repository.ErrNotFound {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		log.Error().Err(err).Msg("revoke token failed")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
