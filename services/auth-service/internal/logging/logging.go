package logging

import (
	"os"
	"strings"
	"time"

	"github.com/rs/zerolog"
)

// NewLogger configures zerolog with level from AUTH_LOG_LEVEL and returns a logger instance
func NewLogger() zerolog.Logger {
	levelStr := os.Getenv("AUTH_LOG_LEVEL")
	level := zerolog.InfoLevel
	switch strings.ToLower(levelStr) {
	case "debug":
		level = zerolog.DebugLevel
	case "info":
		level = zerolog.InfoLevel
	case "warn", "warning":
		level = zerolog.WarnLevel
	case "error":
		level = zerolog.ErrorLevel
	}
	zerolog.TimeFieldFormat = time.RFC3339Nano
	logger := zerolog.New(zerolog.ConsoleWriter{Out: os.Stdout}).With().Timestamp().Logger().Level(level)
	return logger
}
