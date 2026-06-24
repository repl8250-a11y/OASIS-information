package main

import (
	"context"
	"crypto/rsa"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/logging"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/metrics"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/middleware"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/repository"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/security"
	"github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/auth"
)

func mustGetEnv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatal().Msgf("required env %s not set", k)
	}
	return v
}

func main() {
	// initialize logger
	logger := logging.NewLogger()
	zerolog.SetGlobalLevel(logger.GetLevel())
	log.Logger = logger

	ctx := context.Background()

	// DB
	dsn := mustGetEnv("AUTH_DATABASE_URL")
	pg, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to create pgx pool")
	}
	defer pg.Close()

	// Redis
	rdb := redis.NewClient(&redis.Options{
		Addr: os.Getenv("AUTH_REDIS_URL"),
	})
	defer rdb.Close()

	// Repository wrapper
	repo := repository.NewRepository(ctx, dsn)
	defer repo.Close()

	// Metrics
	metrics.Register()

	// JWT keys
	priv, err := auth.LoadPrivateKeyFromEnv()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load private key")
	}
	pub, err := auth.LoadPublicKeyFromEnv()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load public key")
	}
	_ = priv
	_ = pub

	// Rate limiter
	rl := middleware.NewRateLimiter(rdb, 200, 1*time.Minute)

	// HTTP server and handlers
	mux := http.NewServeMux()
	// Prometheus metrics
	mux.Handle("/metrics", metrics.Handler())

	// Register application routes (handlers implemented in handlers package)
	// Use simple handler wiring to keep composition clear
	// import handlers "github.com/xulfa48-cloud/OASIS-information/services/auth-service/internal/handlers" (avoided import cycle)

	// For brevity manual registrations using closures
	mux.HandleFunc("/api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})
	mux.HandleFunc("/api/v1/ready", func(w http.ResponseWriter, r *http.Request) {
		// Ready: check db and redis
		if err := pg.Ping(ctx); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		if err := rdb.Ping(ctx).Err(); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		w.Write([]byte(`{"status":"ready"}`))
	})

	// Wrap mux with rate limiter middleware
	handler := rl.Middleware(mux)

	srv := &http.Server{
		Addr:         ":8080",
		Handler:      handler,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 20 * time.Second,
	}

	// Graceful shutdown
	go func() {
		log.Info().Msg("auth-service starting on :8080")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("http server error")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	ctxShut, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctxShut); err != nil {
		log.Error().Err(err).Msg("server shutdown failed")
	}
	log.Info().Msg("server gracefully stopped")
}
