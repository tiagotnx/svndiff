#!/bin/bash

# Script para instalar git hooks do projeto svndiff
# Uso: ./scripts/install-hooks.sh

set -e

echo "🔧 Instalando Git Hooks para o projeto svndiff..."

# Verificar se estamos em um repositório git
if [ ! -d ".git" ]; then
    echo "❌ Este não é um repositório Git"
    exit 1
fi

# Criar diretório de hooks se não existir
mkdir -p .git/hooks

# Tornar os scripts executáveis
chmod +x scripts/pre-commit.sh
chmod +x scripts/pre-push.sh
chmod +x scripts/test-coverage.sh
chmod +x scripts/integration-tests.sh

# Instalar pre-commit hook
echo "📝 Instalando pre-commit hook..."
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
exec ./scripts/pre-commit.sh
EOF
chmod +x .git/hooks/pre-commit

# Instalar pre-push hook
echo "🚀 Instalando pre-push hook..."
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
exec ./scripts/pre-push.sh
EOF
chmod +x .git/hooks/pre-push

echo "✅ Git hooks instalados com sucesso!"
echo
echo "📋 Hooks instalados:"
echo "  • pre-commit: Verifica formatação, linting e testes unitários"
echo "  • pre-push: Executa testes completos e build multi-plataforma"
echo
echo "💡 Para pular os hooks temporariamente, use:"
echo "  git commit --no-verify"
echo "  git push --no-verify"
