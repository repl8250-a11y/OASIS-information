package auth

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// TokenClaims are the fields we embed in JWT tokens.
type TokenClaims struct {
	UserID string   `json:"sub"`
	Email  string   `json:"email"`
	Roles  []string `json:"roles"`
	jwt.RegisteredClaims
}

// LoadPrivateKeyFromEnv loads RSA private key PEM from AUTH_JWT_PRIVATE_KEY env var
func LoadPrivateKeyFromEnv() (*rsa.PrivateKey, error) {
	pemStr := os.Getenv("AUTH_JWT_PRIVATE_KEY")
	if pemStr == "" {
		return nil, errors.New("AUTH_JWT_PRIVATE_KEY not set")
	}
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil || block.Type != "RSA PRIVATE KEY" {
		return nil, errors.New("invalid RSA private key PEM")
	}
	pk, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return nil, err
	}
	return pk, nil
}

// LoadPublicKeyFromEnv loads RSA public key PEM from AUTH_JWT_PUBLIC_KEY env var
func LoadPublicKeyFromEnv() (*rsa.PublicKey, error) {
	pemStr := os.Getenv("AUTH_JWT_PUBLIC_KEY")
	if pemStr == "" {
		return nil, errors.New("AUTH_JWT_PUBLIC_KEY not set")
	}
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		return nil, errors.New("invalid PEM")
	}
	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return nil, err
	}
	rpk, ok := pub.(*rsa.PublicKey)
	if !ok {
		return nil, errors.New("public key is not RSA")
	}
	return rpk, nil
}

// SignAccessToken signs a JWT (RS256) with private key, expiresIn seconds.
func SignAccessToken(privateKey *rsa.PrivateKey, userID, email string, roles []string, expiresIn time.Duration, issuer string) (string, error) {
	claims := TokenClaims{
		UserID: userID,
		Email:  email,
		Roles:  roles,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    issuer,
			Subject:   userID,
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(expiresIn)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	signed, err := token.SignedString(privateKey)
	if err != nil {
		return "", err
	}
	return signed, nil
}

// VerifyAccessToken verifies token and returns claims
func VerifyAccessToken(publicKey *rsa.PublicKey, tokenStr string) (*TokenClaims, error) {
	parser := jwt.NewParser(jwt.WithValidMethods([]string{"RS256"}))
	var claims TokenClaims
	_, err := parser.ParseWithClaims(tokenStr, &claims, func(token *jwt.Token) (interface{}, error) {
		return publicKey, nil
	})
	if err != nil {
		return nil, err
	}
	return &claims, nil
}
