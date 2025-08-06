// Package main é o ponto de entrada da aplicação svndiff.
package main

import (
	"fmt"
	"os"
	"svndiff/cmd"
)

// Variáveis de build injetadas em tempo de compilação
var (
	version = "dev"
	commit  = "unknown"
	date    = "unknown"
)

func main() {
	// Verificar se é solicitação de versão
	if len(os.Args) > 1 && (os.Args[1] == "--version" || os.Args[1] == "-v") {
		fmt.Printf("svndiff %s (commit: %s, built: %s)\n", version, commit, date)
		return
	}

	cmd.Execute()
}
