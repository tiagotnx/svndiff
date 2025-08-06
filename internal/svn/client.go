// Package svn fornece um wrapper para o comando svn da linha de comando.
// Este package abstrai a execução de comandos SVN e processa suas saídas.
package svn

import (
	"fmt"
	"os/exec"
	"strings"
	"svndiff/pkg/config"
)

// Client representa um cliente SVN que executa comandos via linha de comando
type Client struct {
	auth *config.AuthConfig
}

// NewClient cria uma nova instância do cliente SVN
func NewClient(auth *config.AuthConfig) *Client {
	return &Client{
		auth: auth,
	}
}

// DiffResult representa o resultado de uma operação de diff
type DiffResult struct {
	Output   string
	FileList []string
}

// GetDiff executa um svn diff entre duas branches e suas respectivas revisões
func (c *Client) GetDiff(branchA, branchB *config.BranchConfig, summarize bool) (*DiffResult, error) {
	// Constrói as URLs com as revisões
	urlA := fmt.Sprintf("%s@%s", branchA.URL, branchA.GetLatestRevision())
	urlB := fmt.Sprintf("%s@%s", branchB.URL, branchB.GetLatestRevision())

	// Constrói o comando svn diff
	args := []string{"diff"}

	// Adiciona credenciais se fornecidas
	if c.auth != nil && c.auth.User != "" {
		args = append(args, "--username", c.auth.User)
		if c.auth.Password != "" {
			args = append(args, "--password", c.auth.Password)
		}
	}

	// Adiciona flag de resumo se solicitado
	if summarize {
		args = append(args, "--summarize")
	}

	// Adiciona as URLs para comparação
	args = append(args, urlA, urlB)

	// Executa o comando
	cmd := exec.Command("svn", args...)
	output, err := cmd.Output()
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			return nil, fmt.Errorf("comando svn falhou: %s\nSaída de erro: %s",
				err.Error(), string(exitError.Stderr))
		}
		return nil, fmt.Errorf("erro ao executar comando svn: %w", err)
	}

	result := &DiffResult{
		Output: string(output),
	}

	// Se for um resumo, processa a lista de arquivos
	if summarize {
		result.FileList = c.parseFileList(string(output))
	}

	return result, nil
}

// GetLog obtém o log de uma branch para revisões específicas
func (c *Client) GetLog(branch *config.BranchConfig) (string, error) {
	args := []string{"log"}

	// Adiciona credenciais se fornecidas
	if c.auth != nil && c.auth.User != "" {
		args = append(args, "--username", c.auth.User)
		if c.auth.Password != "" {
			args = append(args, "--password", c.auth.Password)
		}
	}

	// Adiciona o range de revisões
	revisionRange := branch.GetRevisionRange()
	if revisionRange != "" {
		args = append(args, "-r", revisionRange)
	}

	// Adiciona a URL
	args = append(args, branch.URL)

	// Executa o comando
	cmd := exec.Command("svn", args...)
	output, err := cmd.Output()
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			return "", fmt.Errorf("comando svn log falhou: %s\nSaída de erro: %s",
				err.Error(), string(exitError.Stderr))
		}
		return "", fmt.Errorf("erro ao executar comando svn log: %w", err)
	}

	return string(output), nil
}

// CheckConnection verifica se é possível conectar ao repositório SVN
func (c *Client) CheckConnection(url string) error {
	args := []string{"info"}

	// Adiciona credenciais se fornecidas
	if c.auth != nil && c.auth.User != "" {
		args = append(args, "--username", c.auth.User)
		if c.auth.Password != "" {
			args = append(args, "--password", c.auth.Password)
		}
	}

	args = append(args, url)

	cmd := exec.Command("svn", args...)
	_, err := cmd.Output()
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			return fmt.Errorf("não foi possível conectar ao SVN: %s\nSaída de erro: %s",
				err.Error(), string(exitError.Stderr))
		}
		return fmt.Errorf("erro ao verificar conexão SVN: %w", err)
	}

	return nil
}

// parseFileList processa a saída do svn diff --summarize e extrai a lista de arquivos
func (c *Client) parseFileList(output string) []string {
	var files []string
	lines := strings.Split(strings.TrimSpace(output), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// O formato do svn diff --summarize é: "STATUS   PATH"
		// onde STATUS pode ser M (Modified), A (Added), D (Deleted), etc.
		parts := strings.Fields(line)
		if len(parts) >= 2 {
			// O caminho do arquivo é tudo após o primeiro espaço
			filePath := strings.Join(parts[1:], " ")
			files = append(files, filePath)
		}
	}

	return files
}
