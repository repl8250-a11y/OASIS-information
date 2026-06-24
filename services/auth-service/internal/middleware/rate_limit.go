package middleware

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/rs/zerolog/log"
)

// RateLimiter implements a token-bucket per key using Redis INCR with expiry.
// Config via env variables in config package; here we assume 100 requests per minute per key.

type RateLimiter struct {
	rdb    *redis.Client
	limit  int
	window time.Duration
}

func NewRateLimiter(rdb *redis.Client, limit int, window time.Duration) *RateLimiter {
	return &RateLimiter{rdb: rdb, limit: limit, window: window}
}

func (rl *RateLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		key := rl.buildKey(r)
		count, err := rl.rdb.Incr(ctx, key).Result()
		if err != nil {
			log.Error().Err(err).Msg("rate limiter redis error")
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		if count == 1 {
			// set expiry
			_ = rl.rdb.Expire(ctx, key, rl.window).Err()
		}
		if int(count) > rl.limit {
			w.Header().Set("Retry-After", strconv.Itoa(int(rl.window.Seconds())))
			w.WriteHeader(http.StatusTooManyRequests)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (rl *RateLimiter) buildKey(r *http.Request) string {
	// Rate limit by Authorization token if present, else by remote IP
	auth := r.Header.Get("Authorization")
	if auth != "" {
		return "rl:token:" + auth
	}
	ip := r.RemoteAddr
	return "rl:ip:" + ip
}
