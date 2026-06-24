package security

import "testing"

func TestHashAndVerify(t *testing.T) {
	pwd := "s3cureP@ssw0rd!"
	h, err := HashPassword(pwd)
	if err != nil {
		t.Fatalf("hash error: %v", err)
	}
	ok, err := VerifyPassword(h, pwd)
	if err != nil {
		t.Fatalf("verify error: %v", err)
	}
	if !ok {
		t.Fatalf("password verification failed")
	}
}
