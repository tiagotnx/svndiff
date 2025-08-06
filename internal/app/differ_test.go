package app

import (
	"svndiff/pkg/config"
	"testing"
)

func TestDiffer_parseFileChanges(t *testing.T) {
	differ := &Differ{}

	tests := []struct {
		name     string
		output   string
		expected []FileChange
	}{
		{
			name:     "saída vazia",
			output:   "",
			expected: []FileChange{},
		},
		{
			name:   "múltiplos arquivos",
			output: "M       src/main.go\nA       README.md\nD       old_file.txt",
			expected: []FileChange{
				{Path: "src/main.go", Status: "Modified"},
				{Path: "README.md", Status: "Added"},
				{Path: "old_file.txt", Status: "Deleted"},
			},
		},
		{
			name:   "arquivo com espaços no nome",
			output: "M       src/test file.go",
			expected: []FileChange{
				{Path: "src/test file.go", Status: "Modified"},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := differ.parseFileChanges(tt.output)
			if len(result) != len(tt.expected) {
				t.Errorf("parseFileChanges() len = %v, want %v", len(result), len(tt.expected))
				return
			}

			for i, change := range result {
				if change.Path != tt.expected[i].Path || change.Status != tt.expected[i].Status {
					t.Errorf("parseFileChanges()[%d] = %v, want %v", i, change, tt.expected[i])
				}
			}
		})
	}
}

func TestDiffer_mapSVNStatus(t *testing.T) {
	differ := &Differ{}

	tests := []struct {
		status   string
		expected string
	}{
		{"M", "Modified"},
		{"A", "Added"},
		{"D", "Deleted"},
		{"R", "Replaced"},
		{"C", "Conflicted"},
		{"X", "External"},
		{"I", "Ignored"},
		{"?", "Unversioned"},
		{"!", "Missing"},
		{"~", "Obstructed"},
		{"Z", "Z"}, // Status desconhecido deve retornar o original
	}

	for _, tt := range tests {
		t.Run(tt.status, func(t *testing.T) {
			result := differ.mapSVNStatus(tt.status)
			if result != tt.expected {
				t.Errorf("mapSVNStatus(%s) = %s, want %s", tt.status, result, tt.expected)
			}
		})
	}
}

func TestNewDiffer(t *testing.T) {
	cfg := &config.Config{
		Auth: config.AuthConfig{
			User:     "testuser",
			Password: "testpass",
		},
	}

	differ := NewDiffer(cfg)

	if differ == nil {
		t.Error("NewDiffer() returned nil")
	}

	if differ.config != cfg {
		t.Error("NewDiffer() didn't set config correctly")
	}

	if differ.svnClient == nil {
		t.Error("NewDiffer() didn't initialize svn client")
	}
}
