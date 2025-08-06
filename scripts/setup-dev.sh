#!/bin/bash

# Script de configuração do ambiente de desenvolvimento
# Uso: ./scripts/setup-dev.sh

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar se estamos no diretório correto
if [[ ! -f "go.mod" ]] || [[ ! -f "main.go" ]]; then
    log_error "Execute este script na raiz do projeto svndiff"
    exit 1
fi

log_info "🚀 Configurando ambiente de desenvolvimento para svndiff..."

# 1. Verificar Go
log_info "Verificando instalação do Go..."
if ! command -v go &> /dev/null; then
    log_error "Go não está instalado. Visite https://golang.org/dl/"
    exit 1
fi

GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+')
log_success "Go encontrado: $GO_VERSION"

# 2. Baixar dependências
log_info "Baixando dependências..."
go mod download
go mod tidy
log_success "Dependências baixadas"

# 3. Instalar ferramentas de desenvolvimento
log_info "Instalando ferramentas de desenvolvimento..."

# golangci-lint
if ! command -v golangci-lint &> /dev/null; then
    log_info "Instalando golangci-lint..."
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.54.2
    log_success "golangci-lint instalado"
else
    log_success "golangci-lint já está instalado"
fi

# Air para hot reload
if ! command -v air &> /dev/null; then
    log_info "Instalando Air..."
    go install github.com/cosmtrek/air@latest
    log_success "Air instalado"
else
    log_success "Air já está instalado"
fi

# goimports
if ! command -v goimports &> /dev/null; then
    log_info "Instalando goimports..."
    go install golang.org/x/tools/cmd/goimports@latest
    log_success "goimports instalado"
else
    log_success "goimports já está instalado"
fi

# govulncheck
if ! command -v govulncheck &> /dev/null; then
    log_info "Instalando govulncheck..."
    go install golang.org/x/vuln/cmd/govulncheck@latest
    log_success "govulncheck instalado"
else
    log_success "govulncheck já está instalado"
fi

# 4. Tornar scripts executáveis
log_info "Configurando permissões dos scripts..."
chmod +x scripts/*.sh
log_success "Scripts configurados"

# 5. Instalar git hooks
log_info "Instalando git hooks..."
if [[ -d ".git" ]]; then
    ./scripts/install-hooks.sh
    log_success "Git hooks instalados"
else
    log_warning "Não é um repositório git, pulando instalação dos hooks"
fi

# 6. Criar diretórios necessários
log_info "Criando diretórios necessários..."
mkdir -p build dist coverage tmp
log_success "Diretórios criados"

# 7. Verificar SVN (opcional)
if command -v svn &> /dev/null; then
    SVN_VERSION=$(svn --version --quiet)
    log_success "SVN encontrado: $SVN_VERSION"
else
    log_warning "SVN não está instalado. Instale para usar todas as funcionalidades:"
    case "$(uname -s)" in
        Linux*)
            log_info "  Ubuntu/Debian: sudo apt-get install subversion"
            log_info "  CentOS/RHEL: sudo yum install subversion"
            ;;
        Darwin*)
            log_info "  macOS: brew install subversion"
            ;;
        *)
            log_info "  Visite: https://subversion.apache.org/packages.html"
            ;;
    esac
fi

# 8. Executar testes para verificar setup
log_info "Executando testes para verificar setup..."
if go test -v ./...; then
    log_success "Testes passaram"
else
    log_error "Alguns testes falharam"
fi

# 9. Build inicial
log_info "Fazendo build inicial..."
if go build -o build/svndiff .; then
    log_success "Build inicial concluído"
else
    log_error "Build inicial falhou"
    exit 1
fi

echo
log_success "🎉 Ambiente de desenvolvimento configurado com sucesso!"
echo
log_info "📋 Próximos passos:"
echo "  1. Execute 'make help' para ver comandos disponíveis"
echo "  2. Execute 'air' para desenvolvimento com hot reload"
echo "  3. Execute './build/svndiff --help' para testar a aplicação"
echo "  4. Configure seu editor/IDE com as extensões recomendadas"
echo
log_info "🔧 Comandos úteis:"
echo "  make build          - Compilar projeto"
echo "  make test           - Executar testes"
echo "  make lint           - Executar linting"
echo "  make test-coverage  - Testes com cobertura"
echo "  air                 - Hot reload"
echo
log_info "📚 Documentação:"
echo "  README.md           - Documentação principal"
echo "  .vscode/            - Configuração do VS Code"
echo "  scripts/            - Scripts de automação"
