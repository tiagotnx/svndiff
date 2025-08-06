#!/bin/bash

# Script para executar testes com cobertura de código
# Uso: ./scripts/test-coverage.sh

set -e

echo "🧪 Executando testes com cobertura de código..."
echo

# Criar diretório para relatórios se não existir
mkdir -p coverage

# Executar testes com cobertura
echo "📊 Gerando relatório de cobertura..."
go test -v -race -coverprofile=coverage/coverage.out -covermode=atomic ./...

# Verificar se há arquivos de cobertura
if [ ! -f coverage/coverage.out ]; then
    echo "❌ Arquivo de cobertura não foi gerado"
    exit 1
fi

# Gerar relatório HTML
echo "🌐 Gerando relatório HTML..."
go tool cover -html=coverage/coverage.out -o coverage/coverage.html

# Mostrar estatísticas de cobertura
echo "📈 Estatísticas de cobertura:"
go tool cover -func=coverage/coverage.out

# Extrair percentual total de cobertura
COVERAGE=$(go tool cover -func=coverage/coverage.out | grep total | grep -oE '[0-9]+\.[0-9]+')

echo
echo "✅ Cobertura total: ${COVERAGE}%"

# Definir threshold mínimo de cobertura
THRESHOLD=70.0

# Comparar cobertura com threshold
if (( $(echo "$COVERAGE >= $THRESHOLD" | bc -l) )); then
    echo "✅ Cobertura de código está acima do threshold mínimo (${THRESHOLD}%)"
    echo "📋 Relatório HTML disponível em: coverage/coverage.html"
else
    echo "❌ Cobertura de código está abaixo do threshold mínimo (${THRESHOLD}%)"
    exit 1
fi

echo
echo "🎉 Testes executados com sucesso!"
