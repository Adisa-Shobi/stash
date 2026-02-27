package provider

import (
	"fmt"
	"log/slog"
	"sync"
)

type Registry[T any] struct {
	mu        sync.RWMutex
	providers map[string]T
}

func NewRegistry[T any]() *Registry[T] {
	return &Registry[T]{
		providers: make(map[string]T),
	}
}

func (r *Registry[T]) Register(name string, p T) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.providers[name]; exists {
		err := fmt.Errorf("provider already registered: %s", name)
		slog.Error("duplicate provider registration", "name", name)
		return err
	}
	r.providers[name] = p
	return nil
}

func (r *Registry[T]) Get(name string) (T, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	p, ok := r.providers[name]
	if !ok {
		err := fmt.Errorf("no provider registered with name: %s", name)
		slog.Error("provider not found", "name", name)
		return p, err
	}
	return p, nil
}

func (r *Registry[T]) List() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()

	names := make([]string, 0, len(r.providers))
	for name := range r.providers {
		names = append(names, name)
	}
	return names
}
