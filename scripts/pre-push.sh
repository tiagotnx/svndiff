#!/bin/bash

# Git pre-push hook para svndiff
# Este script é executado antes de cada push

set -e

echo "🚀 Executando verificações pre-push..."

# 1. Executar todos os testes com cobertura
echo "🧪 Executando testes com cobertura..."
if ./scripts/test-coverage.sh; then
    echo "✅ Testes com cobertura passaram"
else
    echo "❌ Testes com cobertura falharam"
    exit 1
fi

# 2. Executar testes de integração
echo "🔧 Executando testes de integração..."
if ./scripts/integration-tests.sh; then
    echo "✅ Testes de integração passaram"
else
    echo "❌ Testes de integração falharam"
    exit 1
fi

# 3. Verificar se a aplicação compila para múltiplas plataformas
echo "🏗️  Verificando build para múltiplas plataformas..."

platforms=("linux/amd64" "windows/amd64" "darwin/amd64" "darwin/arm64")

for platform in "${platforms[@]}"; do
    IFS='/' read -r GOOS GOARCH <<< "$platform"
    echo "  📦 Compilando para $GOOS/$GOARCH..."

    if GOOS=$GOOS GOARCH=$GOARCH go build -o /dev/null .; then
        echo "  ✅ $GOOS/$GOARCH build sucesso"
    else
        echo "  ❌ $GOOS/$GOARCH build falhou"
        exit 1
    fi
done

# 4. Verificar se não há secrets ou informações sensíveis
echo "🔒 Verificando por informações sensíveis..."
if grep -r -i "password\|secret\|token\|key" --include="*.go" --include="*.yaml" --include="*.yml" . | grep -v "password:" | grep -v "// password" | grep -v "Password string" | grep -v "exemplo\|example"; then
    echo "❌ Possíveis informações sensíveis encontradas. Verifique os arquivos acima."
    exit 1
else
    echo "✅ Nenhuma informação sensível encontrada"
fi

# 5. Verificar se a documentação está atualizada
echo "📚 Verificando documentação..."
if [ "$(git status --porcelain README.md)" ]; then
    echo "⚠️  README.md foi modificado mas não commitado"
fi

echo "🎉 Todas as verificações pre-push passaram!"
echo "🚀 Push autorizado!"
