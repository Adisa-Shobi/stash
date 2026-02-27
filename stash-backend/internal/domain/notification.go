package domain

import "time"

type NotificationType string

const (
	NotificationPush  NotificationType = "push"
	NotificationSMS   NotificationType = "sms"
	NotificationEmail NotificationType = "email"
)

type Notification struct {
	Type      NotificationType
	Recipient string
	Title     string
	Body      string
	Data      map[string]string
}

type DeliveryReceipt struct {
	ReceiptID string
	Provider  string
	SentAt    time.Time
}

type DeliveryStatus struct {
	ReceiptID  string
	Status     string
	FailReason string
	UpdatedAt  time.Time
}
