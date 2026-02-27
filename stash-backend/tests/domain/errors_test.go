package domain_test

import (
	"errors"
	"testing"

	"github.com/shobi/stash-backend/internal/domain"
)

func TestProviderErrorKindString(t *testing.T) {
	tests := []struct {
		kind domain.ProviderErrorKind
		want string
	}{
		{domain.ErrAuthentication, "authentication"},
		{domain.ErrAuthorization, "authorization"},
		{domain.ErrNotFound, "not_found"},
		{domain.ErrRateLimited, "rate_limited"},
		{domain.ErrValidation, "validation"},
		{domain.ErrUnavailable, "unavailable"},
		{domain.ErrInternal, "internal"},
		{domain.ProviderErrorKind(99), "unknown(99)"},
	}
	for _, tt := range tests {
		if got := tt.kind.String(); got != tt.want {
			t.Errorf("ProviderErrorKind(%d).String() = %q, want %q", tt.kind, got, tt.want)
		}
	}
}

func TestProviderErrorWithoutCause(t *testing.T) {
	e := &domain.ProviderError{
		Kind:      domain.ErrNotFound,
		Provider:  "gmail",
		Operation: "GetMessage",
		Message:   "resource not found",
	}
	want := "gmail.GetMessage: resource not found"
	if got := e.Error(); got != want {
		t.Errorf("Error() = %q, want %q", got, want)
	}
	if e.Unwrap() != nil {
		t.Error("Unwrap() should be nil when Cause is nil")
	}
}

func TestProviderErrorWithCause(t *testing.T) {
	cause := errors.New("connection refused")
	e := &domain.ProviderError{
		Kind:      domain.ErrUnavailable,
		Provider:  "supabase",
		Operation: "ValidateToken",
		Message:   "service unavailable",
		Cause:     cause,
	}
	want := "supabase.ValidateToken: service unavailable: connection refused"
	if got := e.Error(); got != want {
		t.Errorf("Error() = %q, want %q", got, want)
	}
	if e.Unwrap() != cause {
		t.Error("Unwrap() should return the cause")
	}
}

func TestHelperConstructors(t *testing.T) {
	cause := errors.New("test")

	tests := []struct {
		name      string
		err       *domain.ProviderError
		wantKind  domain.ProviderErrorKind
		wantRetry bool
	}{
		{"Authentication", domain.NewAuthenticationError("p", "op", cause), domain.ErrAuthentication, false},
		{"Authorization", domain.NewAuthorizationError("p", "op", cause), domain.ErrAuthorization, false},
		{"NotFound", domain.NewNotFoundError("p", "op", cause), domain.ErrNotFound, false},
		{"RateLimited", domain.NewRateLimitedError("p", "op", cause), domain.ErrRateLimited, true},
		{"Validation", domain.NewValidationError("p", "op", "bad input", cause), domain.ErrValidation, false},
		{"Unavailable", domain.NewUnavailableError("p", "op", cause), domain.ErrUnavailable, true},
		{"Internal", domain.NewInternalError("p", "op", cause), domain.ErrInternal, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.err.Kind != tt.wantKind {
				t.Errorf("Kind = %v, want %v", tt.err.Kind, tt.wantKind)
			}
			if tt.err.Retryable != tt.wantRetry {
				t.Errorf("Retryable = %v, want %v", tt.err.Retryable, tt.wantRetry)
			}
			if tt.err.Provider != "p" || tt.err.Operation != "op" {
				t.Error("Provider/Operation not set correctly")
			}
			if tt.err.Cause != cause {
				t.Error("Cause not set correctly")
			}
		})
	}
}
