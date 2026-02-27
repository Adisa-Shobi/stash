package domain

import "fmt"

type ProviderErrorKind int

const (
	ErrAuthentication ProviderErrorKind = iota
	ErrAuthorization
	ErrNotFound
	ErrRateLimited
	ErrValidation
	ErrUnavailable
	ErrInternal
)

func (k ProviderErrorKind) String() string {
	switch k {
	case ErrAuthentication:
		return "authentication"
	case ErrAuthorization:
		return "authorization"
	case ErrNotFound:
		return "not_found"
	case ErrRateLimited:
		return "rate_limited"
	case ErrValidation:
		return "validation"
	case ErrUnavailable:
		return "unavailable"
	case ErrInternal:
		return "internal"
	default:
		return fmt.Sprintf("unknown(%d)", int(k))
	}
}

type ProviderError struct {
	Kind      ProviderErrorKind
	Provider  string
	Operation string
	Message   string
	Cause     error
	Retryable bool
}

func (e *ProviderError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s.%s: %s: %v", e.Provider, e.Operation, e.Message, e.Cause)
	}
	return fmt.Sprintf("%s.%s: %s", e.Provider, e.Operation, e.Message)
}

func (e *ProviderError) Unwrap() error {
	return e.Cause
}

func NewAuthenticationError(provider, operation string, cause error) *ProviderError {
	return &ProviderError{
		Kind:      ErrAuthentication,
		Provider:  provider,
		Operation: operation,
		Message:   "authentication failed",
		Cause:     cause,
		Retryable: false,
	}
}

func NewAuthorizationError(provider, operation string, cause error) *ProviderError {
	return &ProviderError{
		Kind:      ErrAuthorization,
		Provider:  provider,
		Operation: operation,
		Message:   "insufficient permissions",
		Cause:     cause,
		Retryable: false,
	}
}

func NewNotFoundError(provider, operation string, cause error) *ProviderError {
	return &ProviderError{
		Kind:      ErrNotFound,
		Provider:  provider,
		Operation: operation,
		Message:   "resource not found",
		Cause:     cause,
		Retryable: false,
	}
}

func NewRateLimitedError(provider, operation string, cause error) *ProviderError {
	return &ProviderError{
		Kind:      ErrRateLimited,
		Provider:  provider,
		Operation: operation,
		Message:   "rate limited",
		Cause:     cause,
		Retryable: true,
	}
}

func NewValidationError(provider, operation, message string, cause error) *ProviderError {
	return &ProviderError{
		Kind:      ErrValidation,
		Provider:  provider,
		Operation: operation,
		Message:   message,
		Cause:     cause,
		Retryable: false,
	}
}

func NewUnavailableError(provider, operation string, cause error) *ProviderError {
	return &ProviderError{
		Kind:      ErrUnavailable,
		Provider:  provider,
		Operation: operation,
		Message:   "service unavailable",
		Cause:     cause,
		Retryable: true,
	}
}

func NewInternalError(provider, operation string, cause error) *ProviderError {
	return &ProviderError{
		Kind:      ErrInternal,
		Provider:  provider,
		Operation: operation,
		Message:   "internal error",
		Cause:     cause,
		Retryable: false,
	}
}
