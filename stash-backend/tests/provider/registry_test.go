package provider_test

import (
	"sort"
	"testing"

	"github.com/shobi/stash-backend/internal/provider"
)

type mockProvider struct {
	name string
}

func TestRegistryRegisterAndGet(t *testing.T) {
	r := provider.NewRegistry[*mockProvider]()

	p := &mockProvider{name: "gmail"}
	if err := r.Register("gmail", p); err != nil {
		t.Fatalf("Register() returned unexpected error: %v", err)
	}

	got, err := r.Get("gmail")
	if err != nil {
		t.Fatalf("Get() returned unexpected error: %v", err)
	}
	if got != p {
		t.Error("Get() returned different provider than registered")
	}
}

func TestRegistryGetNotFound(t *testing.T) {
	r := provider.NewRegistry[*mockProvider]()

	_, err := r.Get("nonexistent")
	if err == nil {
		t.Error("Get() should return error for unregistered provider")
	}
}

func TestRegistryDuplicateRegister(t *testing.T) {
	r := provider.NewRegistry[*mockProvider]()

	p := &mockProvider{name: "gmail"}
	if err := r.Register("gmail", p); err != nil {
		t.Fatalf("first Register() returned unexpected error: %v", err)
	}

	if err := r.Register("gmail", p); err == nil {
		t.Error("second Register() should return error for duplicate name")
	}
}

func TestRegistryList(t *testing.T) {
	r := provider.NewRegistry[*mockProvider]()

	_ = r.Register("gmail", &mockProvider{name: "gmail"})
	_ = r.Register("outlook", &mockProvider{name: "outlook"})

	names := r.List()
	sort.Strings(names)

	if len(names) != 2 {
		t.Fatalf("List() returned %d names, want 2", len(names))
	}
	if names[0] != "gmail" || names[1] != "outlook" {
		t.Errorf("List() = %v, want [gmail outlook]", names)
	}
}

func TestRegistryListEmpty(t *testing.T) {
	r := provider.NewRegistry[*mockProvider]()

	names := r.List()
	if len(names) != 0 {
		t.Errorf("List() on empty registry returned %d names, want 0", len(names))
	}
}
