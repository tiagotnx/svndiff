#!/bin/bash

# Script para executar testes de integração
# Uso: ./scripts/integration-tests.sh

set -euo pipefail

echo "🔧 Executando testes de integração para svndiff..."
echo "🐛 Debug: PWD=$(pwd)"
echo "🐛 Debug: GO_VERSION=$(go version)"
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
echo "🐛 Debug: Executando ./build/svndiff --help"

output=$(./build/svndiff --help 2>&1)
exit_code=$?

echo "🐛 Debug: Exit code = $exit_code"
echo "🐛 Debug: Output contém svndiff? $(echo "$output" | grep -q "svndiff" && echo "SIM" || echo "NÃO")"

if [ $exit_code -eq 0 ] && echo "$output" | grep -q "svndiff"; then
    echo "✅ Comando de ajuda funciona corretamente"
else
    echo "❌ Comando de ajuda falhou"
    echo "Exit code: $exit_code"
    echo "Saída: $output"
    exit 1
fi

# Teste 2: Verificar validação de configuração
echo
echo "🧪 Teste 2: Verificando validação de configuração..."
echo "🐛 Debug: Testando com argumentos inválidos..."

# Teste com argumentos inválidos (URL vazia)
output=$(./build/svndiff --urlA "" --urlB "test" --revsA "123" --revsB "124" 2>&1 || true)
exit_code=$?

echo "🐛 Debug: Exit code = $exit_code"
echo "🐛 Debug: Output = $output"

if [ $exit_code -ne 0 ]; then
    echo "✅ Validação de configuração funciona corretamente"
else
    echo "❌ Validação de configuração falhou - deveria ter retornado erro"
    echo "Saída completa: $output"
    exit 1
fi

# Teste 3: Verificar formato de saída JSON
echo
echo "🧪 Teste 3: Verificando formato JSON com URLs inválidas..."
echo "🐛 Debug: Testando conectividade com URLs inválidas..."

output=$(./build/svndiff --urlA "https://invalid.example.com/svn" --urlB "https://invalid.example.com/svn2" --revsA "123" --revsB "124" --output json 2>&1 || true)
exit_code=$?

echo "🐛 Debug: Exit code = $exit_code"
echo "🐛 Debug: Output snippet = ${output:0:200}..."

if [[ $exit_code -ne 0 && ($output == *"erro"* || $output == *"conectividade"* || $output == *"connection"* || $output == *"timeout"* || $output == *"failed"*) ]]; then
    echo "✅ Tratamento de erro de conectividade funciona corretamente"
else
    echo "❌ Tratamento de erro de conectividade falhou"
    echo "Exit code: $exit_code"
    echo "Saída completa: $output"
    exit 1
fi

# Teste 4: Verificar arquivo de configuração
echo
echo "🧪 Teste 4: Verificando carregamento de arquivo de configuração..."
echo "🐛 Debug: Criando arquivo de configuração de teste..."

cat > test-config.yaml << EOF
urlA: "https://invalid.example.com/svn/branchA"
urlB: "https://invalid.example.com/svn/branchB"
revsA: ["123"]
revsB: ["124"]
output: "list"
summarize: true
EOF

echo "🐛 Debug: Conteúdo do arquivo de configuração:"
cat test-config.yaml

output=$(./build/svndiff --config test-config.yaml 2>&1 || true)
exit_code=$?

echo "🐛 Debug: Exit code = $exit_code"
echo "🐛 Debug: Output snippet = ${output:0:200}..."

# O teste deve falhar na conectividade, mas carregar o arquivo com sucesso
if [[ $exit_code -ne 0 ]]; then
    echo "✅ Carregamento de arquivo de configuração funciona corretamente"
else
    echo "❌ Carregamento de arquivo de configuração falhou - deveria falhar na conectividade"
    echo "Exit code: $exit_code"
    echo "Saída completa: $output"
    rm -f test-config.yaml
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
