// Package cmd define os comandos da CLI usando Cobra.
// Este é o ponto de entrada principal da aplicação svndiff.
package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"svndiff/internal/app"
	"svndiff/pkg/config"
)

var (
	cfgFile string
	cfg     config.Config
)

// Variáveis de build injetadas em tempo de compilação
var (
	version = "dev"
	commit  = "unknown"
	date    = "unknown"
)

// getVersion retorna informações de versão formatadas
func getVersion() string {
	return fmt.Sprintf("%s (commit: %s, built: %s)", version, commit, date)
}

// rootCmd representa o comando base quando chamado sem subcomandos
var rootCmd = &cobra.Command{
	Use:   "svndiff",
	Short: "Compara revisões entre duas branches SVN",
	Long: `svndiff é uma ferramenta CLI que compara um conjunto de revisões
de uma branch SVN com um conjunto de revisões de outra branch.

A ferramenta suporta configuração via arquivo YAML e argumentos de linha de comando,
onde os argumentos sempre têm precedência sobre as configurações do arquivo.

Exemplo de uso:
  svndiff --config config.yaml
  svndiff --urlA https://svn.example.com/branchA --revsA 123,124 --urlB https://svn.example.com/branchB --revsB 125 --output diff`,
	Version: getVersion(),
	RunE: func(cmd *cobra.Command, args []string) error {
		// Carrega a configuração do Viper para a struct
		if err := viper.Unmarshal(&cfg); err != nil {
			return fmt.Errorf("erro ao carregar configuração: %w", err)
		}

		// Cria e executa o differ
		differ := app.NewDiffer(&cfg)
		return differ.Run()
	},
}

// Execute adiciona todos os comandos filhos ao comando raiz e define flags adequadamente.
// É chamado por main.main(). Só precisa acontecer uma vez no rootCmd.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Erro: %v\n", err)
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)

	// Flags globais
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "arquivo de configuração (padrão: config.yaml)")

	// Flags para Branch A
	rootCmd.PersistentFlags().String("urlA", "", "URL da Branch A")
	rootCmd.PersistentFlags().StringSlice("revsA", []string{}, "revisões da Branch A (separadas por vírgula)")

	// Flags para Branch B
	rootCmd.PersistentFlags().String("urlB", "", "URL da Branch B")
	rootCmd.PersistentFlags().StringSlice("revsB", []string{}, "revisões da Branch B (separadas por vírgula)")

	// Flags de autenticação
	rootCmd.PersistentFlags().String("user", "", "usuário SVN")
	rootCmd.PersistentFlags().String("password", "", "senha SVN")

	// Flags de saída
	rootCmd.PersistentFlags().String("output", "list", "formato de saída (list, diff, json)")
	rootCmd.PersistentFlags().Bool("summarize", true, "mostrar apenas resumo das diferenças")

	// Vincula flags ao Viper
	_ = viper.BindPFlag("branchA.url", rootCmd.PersistentFlags().Lookup("urlA"))
	_ = viper.BindPFlag("branchA.revisions", rootCmd.PersistentFlags().Lookup("revsA"))
	_ = viper.BindPFlag("branchB.url", rootCmd.PersistentFlags().Lookup("urlB"))
	_ = viper.BindPFlag("branchB.revisions", rootCmd.PersistentFlags().Lookup("revsB"))
	_ = viper.BindPFlag("auth.user", rootCmd.PersistentFlags().Lookup("user"))
	_ = viper.BindPFlag("auth.password", rootCmd.PersistentFlags().Lookup("password"))
	_ = viper.BindPFlag("output", rootCmd.PersistentFlags().Lookup("output"))
	_ = viper.BindPFlag("summarize", rootCmd.PersistentFlags().Lookup("summarize"))
}

// initConfig lê o arquivo de configuração e variáveis de ambiente
func initConfig() {
	if cfgFile != "" {
		// Usa o arquivo de configuração especificado pela flag
		viper.SetConfigFile(cfgFile)
	} else {
		// Procura pelo arquivo de configuração no diretório atual
		viper.AddConfigPath(".")
		viper.SetConfigType("yaml")
		viper.SetConfigName("config")
	}

	// Configura variáveis de ambiente
	viper.SetEnvPrefix("SVNDIFF")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	// Lê o arquivo de configuração
	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintf(os.Stderr, "Usando arquivo de configuração: %s\n", viper.ConfigFileUsed())
	} else {
		// Se não conseguir ler o arquivo, continua com as configurações padrão
		// Isso permite que a ferramenta funcione apenas com flags
		if cfgFile != "" {
			// Se um arquivo foi especificado explicitamente e não foi encontrado, é um erro
			fmt.Fprintf(os.Stderr, "Erro ao ler arquivo de configuração '%s': %v\n", cfgFile, err)
			os.Exit(1)
		}
	}

	// Define valores padrão
	viper.SetDefault("output", "list")
	viper.SetDefault("summarize", true)
}
