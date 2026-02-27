package domain

import "time"

type AuthUser struct {
	ID            string
	Email         string
	Provider      string
	EmailVerified bool
	CreatedAt     time.Time
}

type AuthToken struct {
	AccessToken  string
	RefreshToken string
	ExpiresAt    time.Time
	TokenType    string
}

type SocialProvider string

const (
	SocialGoogle SocialProvider = "google"
	SocialApple  SocialProvider = "apple"
)
