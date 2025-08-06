#!/bin/bash

# Script de exemplo para demonstrar o uso do svndiff

echo "=== Demonstração da CLI svndiff ==="
echo

echo "1. Mostrando ajuda da ferramenta:"
./svndiff.exe --help
echo

echo "2. Exemplo de uso apenas com flags (irá falhar por falta de repositório real):"
echo "   ./svndiff.exe --urlA 'https://svn.example.com/branchA' --revsA '123' --urlB 'https://svn.example.com/branchB' --revsB '124' --output json"
echo

echo "3. Para usar com repositório real, configure o config.yaml com URLs válidas e execute:"
echo "   ./svndiff.exe --config config.yaml"
echo

echo "4. Exemplo de uso com variáveis de ambiente:"
echo "   export SVNDIFF_BRANCHA_URL='https://svn.example.com/branchA'"
echo "   export SVNDIFF_BRANCHB_URL='https://svn.example.com/branchB'"
echo "   export SVNDIFF_OUTPUT='json'"
echo "   ./svndiff.exe"
echo

echo "=== Demonstração concluída ==="
