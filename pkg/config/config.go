// Package config define as estruturas de configuração para a CLI svndiff.
// Estas estruturas mapeiam diretamente para o arquivo config.yaml e são
// usadas pelo Viper para carregar e gerenciar a configuração.
package config

import (
	"fmt"
	"strings"
)

// Config representa a configuração principal da aplicação
type Config struct {
	BranchA   BranchConfig `mapstructure:"branchA"`
	BranchB   BranchConfig `mapstructure:"branchB"`
	Auth      AuthConfig   `mapstructure:"auth"`
	Output    string       `mapstructure:"output"`
	Summarize bool         `mapstructure:"summarize"`
}

// BranchConfig contém a configuração para uma branch SVN específica
type BranchConfig struct {
	URL       string   `mapstructure:"url"`
	Revisions []string `mapstructure:"revisions"`
}

// AuthConfig contém as credenciais de autenticação para o SVN
type AuthConfig struct {
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
}

// Validate verifica se a configuração é válida
func (c *Config) Validate() error {
	if c.BranchA.URL == "" {
		return fmt.Errorf("URL da Branch A é obrigatória")
	}
	if c.BranchB.URL == "" {
		return fmt.Errorf("URL da Branch B é obrigatória")
	}
	if len(c.BranchA.Revisions) == 0 {
		return fmt.Errorf("pelo menos uma revisão da Branch A é obrigatória")
	}
	if len(c.BranchB.Revisions) == 0 {
		return fmt.Errorf("pelo menos uma revisão da Branch B é obrigatória")
	}

	// Valida o formato de saída
	validOutputs := []string{"list", "diff", "json"}
	valid := false
	for _, validOutput := range validOutputs {
		if c.Output == validOutput {
			valid = true
			break
		}
	}
	if !valid {
		return fmt.Errorf("formato de saída inválido '%s'. Opções válidas: %s",
			c.Output, strings.Join(validOutputs, ", "))
	}

	return nil
}

// GetLatestRevision retorna a última (maior) revisão de uma branch
func (bc *BranchConfig) GetLatestRevision() string {
	if len(bc.Revisions) == 0 {
		return ""
	}

	// Para simplificar, assumimos que a última revisão na lista é a mais recente
	// Em uma implementação mais robusta, poderíamos comparar numericamente
	return bc.Revisions[len(bc.Revisions)-1]
}

// GetRevisionRange retorna o range de revisões como uma string "primeira:última"
func (bc *BranchConfig) GetRevisionRange() string {
	if len(bc.Revisions) == 0 {
		return ""
	}
	if len(bc.Revisions) == 1 {
		return bc.Revisions[0]
	}
	return fmt.Sprintf("%s:%s", bc.Revisions[0], bc.Revisions[len(bc.Revisions)-1])
}
