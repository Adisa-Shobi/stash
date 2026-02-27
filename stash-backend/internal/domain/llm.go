package domain

import "time"

type ExtractionRequest struct {
	EmailBody   string
	SenderEmail string
	SenderName  string
	Subject     string
}

type ExtractedTransaction struct {
	Amount          float64
	Currency        string
	MerchantName    string
	RawMerchantName string
	TransactionDate time.Time
	Description     string
	PaymentMethod   string
	IsRecurring     bool
	Confidence      float64
}

type CategorizationRequest struct {
	MerchantName  string
	Amount        float64
	Currency      string
	Description   string
	PaymentMethod string
}

type CategorizedTransaction struct {
	Category    string
	Subcategory string
	Confidence  float64
}
