package domain

import "time"

type ExchangeRate struct {
	From       string
	To         string
	Rate       float64
	Source     string
	FetchedAt  time.Time
	ValidUntil time.Time
}
