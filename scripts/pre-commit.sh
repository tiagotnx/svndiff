#!/bin/bash

# Git pre-commit hook para svndiff
# Este script é executado antes de cada commit

set -e

echo "🔍 Executando verificações pre-commit..."

# 1. Verificar formatação do código
echo "📝 Verificando formatação do código..."
if ! gofmt -l . | grep -q .; then
    echo "✅ Código está formatado corretamente"
else
    echo "❌ Código não está formatado. Execute 'go fmt ./...' e tente novamente."
    echo "Arquivos que precisam de formatação:"
    gofmt -l .
    exit 1
fi

# 2. Executar go vet
echo "🔍 Executando go vet..."
if go vet ./...; then
    echo "✅ go vet passou"
else
    echo "❌ go vet encontrou problemas"
    exit 1
fi

# 3. Executar golangci-lint se disponível
if command -v golangci-lint &> /dev/null; then
    echo "🔍 Executando golangci-lint..."
    if golangci-lint run; then
        echo "✅ golangci-lint passou"
    else
        echo "❌ golangci-lint encontrou problemas"
        exit 1
    fi
else
    echo "⚠️  golangci-lint não está instalado, pulando verificação"
fi

# 4. Executar testes unitários
echo "🧪 Executando testes unitários..."
if go test -race -short ./...; then
    echo "✅ Testes unitários passaram"
else
    echo "❌ Testes unitários falharam"
    exit 1
fi

# 5. Verificar se go.mod está atualizado
echo "📦 Verificando go.mod..."
go mod tidy
if git diff --exit-code go.mod go.sum; then
    echo "✅ go.mod está atualizado"
else
    echo "❌ go.mod precisa ser atualizado. Execute 'go mod tidy' e adicione as mudanças."
    exit 1
fi

echo "🎉 Todas as verificações pre-commit passaram!"
