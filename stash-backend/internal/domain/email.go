package domain

import "time"

type OAuthToken struct {
	AccessToken  string
	RefreshToken string
	ExpiresAt    time.Time
	Scopes       []string
}

type EmailSubscription struct {
	SubscriptionID string
	ExpiresAt      time.Time
}

type EmailMessage struct {
	MessageID  string
	From       string
	Subject    string
	Body       string
	ReceivedAt time.Time
	InternalID string
}

type PushNotification struct {
	EmailAddress string
	HistoryID    uint64
}
