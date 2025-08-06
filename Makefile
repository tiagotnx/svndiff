# Makefile para automatizar tarefas do projeto svndiff

# Variáveis
BINARY_NAME=svndiff
MAIN_PATH=./main.go
BUILD_DIR=build
DIST_DIR=dist

# Comandos padrão
.PHONY: all build clean test lint install help

all: clean test build

# Compilar o projeto
build:
	@echo "Compilando $(BINARY_NAME)..."
	@go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)
	@echo "✓ Compilação concluída: $(BUILD_DIR)/$(BINARY_NAME)"

# Compilar para múltiplas plataformas
build-all:
	@echo "Compilando para múltiplas plataformas..."
	@mkdir -p $(DIST_DIR)
	@GOOS=linux GOARCH=amd64 go build -o $(DIST_DIR)/$(BINARY_NAME)-linux-amd64 $(MAIN_PATH)
	@GOOS=windows GOARCH=amd64 go build -o $(DIST_DIR)/$(BINARY_NAME)-windows-amd64.exe $(MAIN_PATH)
	@GOOS=darwin GOARCH=amd64 go build -o $(DIST_DIR)/$(BINARY_NAME)-darwin-amd64 $(MAIN_PATH)
	@GOOS=darwin GOARCH=arm64 go build -o $(DIST_DIR)/$(BINARY_NAME)-darwin-arm64 $(MAIN_PATH)
	@echo "✓ Compilação para múltiplas plataformas concluída"

# Executar testes
test:
	@echo "Executando testes..."
	@go test -v ./...
	@echo "✓ Testes concluídos"

# Executar testes com cobertura
test-coverage:
	@echo "Executando testes com cobertura..."
	@go test -cover ./...
	@go test -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "✓ Relatório de cobertura gerado: coverage.html"

# Lint do código
lint:
	@echo "Executando linting..."
	@go fmt ./...
	@go vet ./...
	@echo "✓ Linting concluído"

# Instalar o binário
install:
	@echo "Instalando $(BINARY_NAME)..."
	@go install
	@echo "✓ $(BINARY_NAME) instalado com sucesso"

# Baixar dependências
deps:
	@echo "Baixando dependências..."
	@go mod download
	@go mod tidy
	@echo "✓ Dependências atualizadas"

# Limpar arquivos gerados
clean:
	@echo "Limpando arquivos gerados..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@rm -f coverage.out coverage.html
	@echo "✓ Limpeza concluída"

# Executar exemplo
run-example:
	@echo "Executando exemplo..."
	@go run $(MAIN_PATH) --help

# Validar configuração de exemplo
validate-config:
	@echo "Validando configuração de exemplo..."
	@go run $(MAIN_PATH) --config config-example.yaml --help

# Mostrar ajuda
help:
	@echo "Comandos disponíveis:"
	@echo "  build         - Compilar o projeto"
	@echo "  build-all     - Compilar para múltiplas plataformas"
	@echo "  test          - Executar testes"
	@echo "  test-coverage - Executar testes com cobertura"
	@echo "  lint          - Executar linting do código"
	@echo "  install       - Instalar o binário"
	@echo "  deps          - Baixar e atualizar dependências"
	@echo "  clean         - Limpar arquivos gerados"
	@echo "  run-example   - Executar exemplo"
	@echo "  validate-config - Validar configuração de exemplo"
	@echo "  help          - Mostrar esta ajuda"
