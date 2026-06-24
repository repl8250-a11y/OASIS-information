package security

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"golang.org/x/crypto/argon2"
)

// Parameters for Argon2id hashing chosen for production workloads with moderate CPU/memory.
const (
	ArgonTime    = 3
	ArgonMemory  = 64 * 1024 // 64 MB
	ArgonThreads = 4
	ArgonKeyLen  = 32
	SaltLen      = 16
)

// HashPassword returns the Argon2id hash and encoded salt using the format: base64(salt)$base64(hash)
func HashPassword(password string) (string, error) {
	if password == "" {
		return "", errors.New("password cannot be empty")
	}

	salt := make([]byte, SaltLen)
	if _, err := rand.Read(salt); err != nil {
		return "", fmt.Errorf("failed to generate salt: %w", err)
	}

	hash := argon2.IDKey([]byte(password), salt, ArgonTime, ArgonMemory, ArgonThreads, ArgonKeyLen)

	saltEnc := base64.RawStdEncoding.EncodeToString(salt)
	hashEnc := base64.RawStdEncoding.EncodeToString(hash)

	return fmt.Sprintf("%s$%s", saltEnc, hashEnc), nil
}

// VerifyPassword verifies a password against the stored encoded value produced by HashPassword.
func VerifyPassword(stored, password string) (bool, error) {
	if stored == "" || password == "" {
		return false, errors.New("invalid arguments")
	}

	parts := splitStored(stored)
	if len(parts) != 2 {
		return false, errors.New("malformed stored password")
	}

	salt, err := base64.RawStdEncoding.DecodeString(parts[0])
	if err != nil {
		return false, fmt.Errorf("invalid salt encoding: %w", err)
	}
	expected, err := base64.RawStdEncoding.DecodeString(parts[1])
	if err != nil {
		return false, fmt.Errorf("invalid hash encoding: %w", err)
	}

	candidate := argon2.IDKey([]byte(password), salt, ArgonTime, ArgonMemory, ArgonThreads, uint32(len(expected)))

	if len(candidate) != len(expected) {
		return false, nil
	}

	// Constant time comparison
	var diff byte
	for i := 0; i < len(expected); i++ {
		diff |= expected[i] ^ candidate[i]
	}

	return diff == 0, nil
}

func splitStored(s string) []string {
	for i := 0; i < len(s); i++ {
		if s[i] == '$' {
			return []string{s[:i], s[i+1:]}
		}
	}
	return []string{}
}
