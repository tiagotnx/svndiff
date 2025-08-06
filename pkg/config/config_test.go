package config

import (
	"testing"
)

func TestConfig_Validate(t *testing.T) {
	tests := []struct {
		name    string
		config  Config
		wantErr bool
	}{
		{
			name: "configuração válida",
			config: Config{
				BranchA: BranchConfig{
					URL:       "https://svn.example.com/branchA",
					Revisions: []string{"123"},
				},
				BranchB: BranchConfig{
					URL:       "https://svn.example.com/branchB",
					Revisions: []string{"124"},
				},
				Output: "list",
			},
			wantErr: false,
		},
		{
			name: "URL da Branch A vazia",
			config: Config{
				BranchA: BranchConfig{
					URL:       "",
					Revisions: []string{"123"},
				},
				BranchB: BranchConfig{
					URL:       "https://svn.example.com/branchB",
					Revisions: []string{"124"},
				},
				Output: "list",
			},
			wantErr: true,
		},
		{
			name: "formato de saída inválido",
			config: Config{
				BranchA: BranchConfig{
					URL:       "https://svn.example.com/branchA",
					Revisions: []string{"123"},
				},
				BranchB: BranchConfig{
					URL:       "https://svn.example.com/branchB",
					Revisions: []string{"124"},
				},
				Output: "invalid",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := tt.config.Validate(); (err != nil) != tt.wantErr {
				t.Errorf("Config.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestBranchConfig_GetLatestRevision(t *testing.T) {
	tests := []struct {
		name     string
		bc       BranchConfig
		expected string
	}{
		{
			name: "múltiplas revisões",
			bc: BranchConfig{
				Revisions: []string{"123", "124", "125"},
			},
			expected: "125",
		},
		{
			name: "uma revisão",
			bc: BranchConfig{
				Revisions: []string{"123"},
			},
			expected: "123",
		},
		{
			name: "nenhuma revisão",
			bc: BranchConfig{
				Revisions: []string{},
			},
			expected: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.bc.GetLatestRevision(); got != tt.expected {
				t.Errorf("BranchConfig.GetLatestRevision() = %v, want %v", got, tt.expected)
			}
		})
	}
}

func TestBranchConfig_GetRevisionRange(t *testing.T) {
	tests := []struct {
		name     string
		bc       BranchConfig
		expected string
	}{
		{
			name: "múltiplas revisões",
			bc: BranchConfig{
				Revisions: []string{"123", "124", "125"},
			},
			expected: "123:125",
		},
		{
			name: "uma revisão",
			bc: BranchConfig{
				Revisions: []string{"123"},
			},
			expected: "123",
		},
		{
			name: "nenhuma revisão",
			bc: BranchConfig{
				Revisions: []string{},
			},
			expected: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.bc.GetRevisionRange(); got != tt.expected {
				t.Errorf("BranchConfig.GetRevisionRange() = %v, want %v", got, tt.expected)
			}
		})
	}
}
