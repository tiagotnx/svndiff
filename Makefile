# Makefile para automatizar tarefas do projeto svndiff

# Variáveis
BINARY_NAME=svndiff
MAIN_PATH=./main.go
BUILD_DIR=build
DIST_DIR=dist
COVERAGE_DIR=coverage

# Informações de versão
VERSION := $(shell git describe --tags --always --dirty 2>nul || echo "dev")
COMMIT := $(shell git rev-parse --short HEAD 2>nul || echo "unknown")
DATE := $(shell powershell -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'" 2>nul || echo "unknown")

# Flags de build
LDFLAGS=-ldflags "-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)"

# Comandos padrão
.PHONY: all build clean test lint install help setup dev docker

all: clean lint test build

# Compilar o projeto
build:
	@echo "Compilando $(BINARY_NAME)..."
	@if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)
	@go build -o $(BUILD_DIR)/$(BINARY_NAME).exe $(MAIN_PATH)
	@echo "✓ Compilação concluída: $(BUILD_DIR)/$(BINARY_NAME).exe"

# Compilar para múltiplas plataformas
build-all:
	@echo "Compilando para múltiplas plataformas..."
	@if not exist $(DIST_DIR) mkdir $(DIST_DIR)
	@set GOOS=linux& set GOARCH=amd64& go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-linux-amd64 $(MAIN_PATH)
	@set GOOS=linux& set GOARCH=arm64& go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-linux-arm64 $(MAIN_PATH)
	@set GOOS=windows& set GOARCH=amd64& go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-windows-amd64.exe $(MAIN_PATH)
	@set GOOS=darwin& set GOARCH=amd64& go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-darwin-amd64 $(MAIN_PATH)
	@set GOOS=darwin& set GOARCH=arm64& go build $(LDFLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-darwin-arm64 $(MAIN_PATH)
	@echo "✓ Compilação para múltiplas plataformas concluída"

# Executar testes
test:
	@echo "Executando testes..."
	@go test -v ./...
	@echo "✓ Testes concluídos"

# Executar testes com cobertura
test-coverage:
	@echo "Executando testes com cobertura..."
	@if not exist $(COVERAGE_DIR) mkdir $(COVERAGE_DIR)
	@go test -v -coverprofile=$(COVERAGE_DIR)/coverage.out -covermode=atomic ./...
	@go tool cover -html=$(COVERAGE_DIR)/coverage.out -o $(COVERAGE_DIR)/coverage.html
	@go tool cover -func=$(COVERAGE_DIR)/coverage.out
	@echo "✓ Relatório de cobertura gerado: $(COVERAGE_DIR)/coverage.html"

# Executar testes de integração
test-integration:
	@echo "Executando testes de integração..."
	@if exist scripts\integration-tests.sh powershell -Command "& '.\scripts\integration-tests.sh'"
	@echo "✓ Testes de integração concluídos"

# Lint do código
lint:
	@echo "Executando linting..."
	@go fmt ./...
	@gofumpt -w .
	@go vet ./...
	@echo "✓ Linting concluído"

# Verificação de segurança
security:
	@echo "Executando verificação de segurança..."
	@if command -v govulncheck >/dev/null 2>&1; then \
		govulncheck ./...; \
	else \
		echo "⚠️  govulncheck não encontrado, execute 'make setup' primeiro"; \
	fi
	@echo "✓ Verificação de segurança concluída"

# Instalar o binário
install:
	@echo "Instalando $(BINARY_NAME)..."
	@go install
	@echo "✓ $(BINARY_NAME) instalado com sucesso"

# Configurar ambiente de desenvolvimento
setup:
	@echo "Configurando ambiente de desenvolvimento..."
	@if exist scripts\setup-dev.sh powershell -Command "& '.\scripts\setup-dev.sh'"
	@echo "✓ Ambiente configurado"

# Desenvolvimento com hot reload
dev:
	@echo "Iniciando desenvolvimento com hot reload..."
	@if command -v air >/dev/null 2>&1; then \
		air -c .air.toml; \
	else \
		echo "⚠️  Air não encontrado, execute 'make setup' primeiro"; \
		exit 1; \
	fi

# Comandos Docker
docker-build:
	@echo "Construindo imagem Docker..."
	@docker build -t $(BINARY_NAME):latest .
	@echo "✓ Imagem Docker construída"

docker-dev:
	@echo "Iniciando ambiente de desenvolvimento Docker..."
	@docker-compose up svndiff-dev

docker-test:
	@echo "Executando testes no Docker..."
	@docker-compose --profile test up svndiff-test

# Instalar git hooks
install-hooks:
	@echo "Instalando git hooks..."
	@if exist scripts\install-hooks.sh powershell -Command "& '.\scripts\install-hooks.sh'"
	@echo "✓ Git hooks instalados"

# Baixar dependências
deps:
	@echo "Baixando dependências..."
	@go mod download
	@go mod tidy
	@echo "✓ Dependências atualizadas"

# Limpar arquivos gerados
clean:
	@echo "Limpando arquivos gerados..."
	@if exist $(BUILD_DIR) rmdir /S /Q $(BUILD_DIR)
	@if exist $(DIST_DIR) rmdir /S /Q $(DIST_DIR)
	@if exist $(COVERAGE_DIR) rmdir /S /Q $(COVERAGE_DIR)
	@if exist coverage.out del coverage.out
	@if exist coverage.html del coverage.html
	@if exist tmp rmdir /S /Q tmp
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
	@echo "  build             - Compilar o projeto"
	@echo "  build-all         - Compilar para múltiplas plataformas"
	@echo "  test              - Executar testes"
	@echo "  test-coverage     - Executar testes com cobertura"
	@echo "  test-integration  - Executar testes de integração"
	@echo "  lint              - Executar linting do código"
	@echo "  security          - Verificação de segurança"
	@echo "  install           - Instalar o binário"
	@echo "  setup             - Configurar ambiente de desenvolvimento"
	@echo "  dev               - Desenvolvimento com hot reload"
	@echo "  deps              - Baixar e atualizar dependências"
	@echo "  clean             - Limpar arquivos gerados"
	@echo "  docker-build      - Construir imagem Docker"
	@echo "  docker-dev        - Ambiente de desenvolvimento Docker"
	@echo "  docker-test       - Executar testes no Docker"
	@echo "  install-hooks     - Instalar git hooks"
	@echo "  help              - Mostrar esta ajuda"
