// Package app contém a lógica de orquestração principal da aplicação svndiff.
// Este package conecta a configuração, o cliente SVN e os formatadores de saída.
package app

import (
	"encoding/json"
	"fmt"
	"strings"
	"svndiff/internal/svn"
	"svndiff/pkg/config"

	"github.com/fatih/color"
)

// Differ é a estrutura principal que orquestra as operações de diff
type Differ struct {
	config    *config.Config
	svnClient *svn.Client
}

// NewDiffer cria uma nova instância do Differ
func NewDiffer(cfg *config.Config) *Differ {
	svnClient := svn.NewClient(&cfg.Auth)
	return &Differ{
		config:    cfg,
		svnClient: svnClient,
	}
}

// FileChange representa uma mudança em um arquivo
type FileChange struct {
	Path   string `json:"path"`
	Status string `json:"status"`
}

// DiffSummary representa um resumo das diferenças
type DiffSummary struct {
	BranchA    BranchInfo   `json:"branchA"`
	BranchB    BranchInfo   `json:"branchB"`
	Changes    []FileChange `json:"changes"`
	TotalFiles int          `json:"totalFiles"`
}

// BranchInfo contém informações sobre uma branch
type BranchInfo struct {
	URL       string   `json:"url"`
	Revisions []string `json:"revisions"`
	Latest    string   `json:"latest"`
}

// Run executa a operação principal de diff
func (d *Differ) Run() error {
	// Valida a configuração
	if err := d.config.Validate(); err != nil {
		return fmt.Errorf("configuração inválida: %w", err)
	}

	// Verifica conectividade (opcional, mas útil para debug)
	if err := d.checkConnections(); err != nil {
		return fmt.Errorf("erro de conectividade: %w", err)
	}

	// Executa o diff baseado no formato de saída solicitado
	switch d.config.Output {
	case "list":
		return d.outputList()
	case "diff":
		return d.outputDiff()
	case "json":
		return d.outputJSON()
	default:
		return fmt.Errorf("formato de saída não suportado: %s", d.config.Output)
	}
}

// checkConnections verifica se é possível conectar às branches SVN
func (d *Differ) checkConnections() error {
	if err := d.svnClient.CheckConnection(d.config.BranchA.URL); err != nil {
		return fmt.Errorf("falha ao conectar à Branch A (%s): %w", d.config.BranchA.URL, err)
	}

	if err := d.svnClient.CheckConnection(d.config.BranchB.URL); err != nil {
		return fmt.Errorf("falha ao conectar à Branch B (%s): %w", d.config.BranchB.URL, err)
	}

	return nil
}

// outputList gera uma saída simples listando os arquivos modificados
func (d *Differ) outputList() error {
	result, err := d.svnClient.GetDiff(&d.config.BranchA, &d.config.BranchB, true)
	if err != nil {
		return fmt.Errorf("erro ao executar diff: %w", err)
	}

	// Imprime cabeçalho informativo
	d.printHeader()

	// Se não há diferenças
	if len(result.FileList) == 0 {
		color.Green("✓ Nenhuma diferença encontrada entre as branches.\n")
		return nil
	}

	// Imprime a lista de arquivos
	color.Yellow("Arquivos modificados (%d):\n", len(result.FileList))
	for _, file := range result.FileList {
		fmt.Printf("  %s\n", file)
	}

	return nil
}

// outputDiff gera a saída completa do diff unificado
func (d *Differ) outputDiff() error {
	result, err := d.svnClient.GetDiff(&d.config.BranchA, &d.config.BranchB, false)
	if err != nil {
		return fmt.Errorf("erro ao executar diff: %w", err)
	}

	// Imprime cabeçalho informativo
	d.printHeader()

	// Se não há diferenças
	if strings.TrimSpace(result.Output) == "" {
		color.Green("✓ Nenhuma diferença encontrada entre as branches.\n")
		return nil
	}

	// Imprime o diff com coloração
	d.printColorizedDiff(result.Output)

	return nil
}

// outputJSON gera a saída em formato JSON
func (d *Differ) outputJSON() error {
	result, err := d.svnClient.GetDiff(&d.config.BranchA, &d.config.BranchB, true)
	if err != nil {
		return fmt.Errorf("erro ao executar diff: %w", err)
	}

	// Constrói o objeto de resumo
	summary := DiffSummary{
		BranchA: BranchInfo{
			URL:       d.config.BranchA.URL,
			Revisions: d.config.BranchA.Revisions,
			Latest:    d.config.BranchA.GetLatestRevision(),
		},
		BranchB: BranchInfo{
			URL:       d.config.BranchB.URL,
			Revisions: d.config.BranchB.Revisions,
			Latest:    d.config.BranchB.GetLatestRevision(),
		},
		Changes:    d.parseFileChanges(result.Output),
		TotalFiles: len(result.FileList),
	}

	// Serializa para JSON
	jsonOutput, err := json.MarshalIndent(summary, "", "  ")
	if err != nil {
		return fmt.Errorf("erro ao gerar JSON: %w", err)
	}

	fmt.Println(string(jsonOutput))
	return nil
}

// printHeader imprime um cabeçalho informativo
func (d *Differ) printHeader() {
	color.Cyan("=== SVN Diff Comparison ===\n")
	fmt.Printf("Branch A: %s @ %s\n", d.config.BranchA.URL, d.config.BranchA.GetLatestRevision())
	fmt.Printf("Branch B: %s @ %s\n", d.config.BranchB.URL, d.config.BranchB.GetLatestRevision())
	fmt.Println()
}

// printColorizedDiff imprime o diff com cores para melhor legibilidade
func (d *Differ) printColorizedDiff(diffOutput string) {
	lines := strings.Split(diffOutput, "\n")

	for _, line := range lines {
		switch {
		case strings.HasPrefix(line, "+++") || strings.HasPrefix(line, "---"):
			color.Blue(line)
		case strings.HasPrefix(line, "@@"):
			color.Magenta(line)
		case strings.HasPrefix(line, "+"):
			color.Green(line)
		case strings.HasPrefix(line, "-"):
			color.Red(line)
		case strings.HasPrefix(line, "Index:") || strings.HasPrefix(line, "==="):
			color.Yellow(line)
		default:
			fmt.Println(line)
		}
	}
}

// parseFileChanges processa a saída do diff e extrai as mudanças de arquivo com status
func (d *Differ) parseFileChanges(output string) []FileChange {
	var changes []FileChange
	lines := strings.Split(strings.TrimSpace(output), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// O formato do svn diff --summarize é: "STATUS   PATH"
		parts := strings.Fields(line)
		if len(parts) >= 2 {
			status := parts[0]
			filePath := strings.Join(parts[1:], " ")

			// Mapeia os status SVN para nomes mais legíveis
			statusName := d.mapSVNStatus(status)

			changes = append(changes, FileChange{
				Path:   filePath,
				Status: statusName,
			})
		}
	}

	return changes
}

// mapSVNStatus mapeia códigos de status SVN para nomes legíveis
func (d *Differ) mapSVNStatus(status string) string {
	statusMap := map[string]string{
		"M": "Modified",
		"A": "Added",
		"D": "Deleted",
		"R": "Replaced",
		"C": "Conflicted",
		"X": "External",
		"I": "Ignored",
		"?": "Unversioned",
		"!": "Missing",
		"~": "Obstructed",
	}

	if mapped, exists := statusMap[status]; exists {
		return mapped
	}

	return status // Retorna o status original se não encontrado
}
