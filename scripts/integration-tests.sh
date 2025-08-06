#!/bin/bash

# Script para executar testes de integração
# Uso: ./scripts/integration-tests.sh

set -e

echo "🔧 Executando testes de integração para svndiff..."
echo

# Verificar se o SVN está instalado
if ! command -v svn &> /dev/null; then
    echo "❌ SVN não está instalado ou não está no PATH"
    exit 1
fi

echo "✅ SVN está disponível: $(svn --version --quiet)"

# Compilar a aplicação
echo "🏗️  Compilando aplicação..."
go build -o ./build/svndiff .

if [ ! -f "./build/svndiff" ]; then
    echo "❌ Falha ao compilar a aplicação"
    exit 1
fi

echo "✅ Aplicação compilada com sucesso"

# Teste 1: Verificar help
echo
echo "🧪 Teste 1: Verificando comando de ajuda..."
./build/svndiff --help > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Comando de ajuda funciona corretamente"
else
    echo "❌ Comando de ajuda falhou"
    exit 1
fi

# Teste 2: Verificar validação de configuração
echo
echo "🧪 Teste 2: Verificando validação de configuração..."
./build/svndiff --urlA "" --urlB "test" --revsA "123" --revsB "124" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "✅ Validação de configuração funciona corretamente"
else
    echo "❌ Validação de configuração falhou"
    exit 1
fi

# Teste 3: Verificar formato de saída JSON
echo
echo "🧪 Teste 3: Verificando formato JSON com URLs inválidas..."
output=$(./build/svndiff --urlA "https://invalid.example.com/svn" --urlB "https://invalid.example.com/svn2" --revsA "123" --revsB "124" --output json 2>&1 || true)

if [[ $output == *"erro de conectividade"* ]]; then
    echo "✅ Tratamento de erro de conectividade funciona corretamente"
else
    echo "❌ Tratamento de erro de conectividade falhou"
    echo "Saída: $output"
    exit 1
fi

# Teste 4: Verificar arquivo de configuração
echo
echo "🧪 Teste 4: Verificando carregamento de arquivo de configuração..."
cat > test-config.yaml << EOF
branchA:
  url: "https://invalid.example.com/svn/branchA"
  revisions:
    - "123"
branchB:
  url: "https://invalid.example.com/svn/branchB"
  revisions:
    - "124"
output: "list"
summarize: true
EOF

output=$(./build/svndiff --config test-config.yaml 2>&1 || true)

if [[ $output == *"Usando arquivo de configuração"* ]] && [[ $output == *"test-config.yaml"* ]]; then
    echo "✅ Carregamento de arquivo de configuração funciona corretamente"
else
    echo "❌ Carregamento de arquivo de configuração falhou"
    echo "Saída: $output"
    exit 1
fi

# Limpeza
rm -f test-config.yaml

echo
echo "🎉 Todos os testes de integração passaram!"
echo "📋 Resumo dos testes:"
echo "  ✅ Comando de ajuda"
echo "  ✅ Validação de configuração"
echo "  ✅ Tratamento de erro de conectividade"
echo "  ✅ Carregamento de arquivo de configuração"
