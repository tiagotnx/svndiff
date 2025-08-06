# svndiff

Uma ferramenta CLI em Go para comparar revisões entre duas branches SVN com configuração flexível via arquivo YAML e argumentos de linha de comando.

## 📋 Índice

-   [Características](#características)
-   [Instalação](#instalação)
-   [Configuração](#configuração)
-   [Uso](#uso)
-   [Exemplos](#exemplos)
-   [Flags Disponíveis](#flags-disponíveis)
-   [Formatos de Saída](#formatos-de-saída)
-   [Desenvolvimento](#desenvolvimento)

## ✨ Características

-   🔧 **Configuração Flexível**: Use arquivos YAML ou flags de linha de comando
-   🌿 **Comparação de Branches**: Compare múltiplas revisões entre duas branches SVN
-   📊 **Múltiplos Formatos**: Saída em lista simples, diff unificado ou JSON
-   🎨 **Saída Colorida**: Diff colorido para melhor legibilidade
-   🔐 **Autenticação**: Suporte para credenciais SVN
-   ⚡ **Performance**: Wrapper eficiente sobre comandos SVN nativos
-   🛡️ **Tratamento de Erros**: Validação robusta e mensagens de erro claras

## 🚀 Instalação

### Pré-requisitos

-   Go 1.21 ou superior
-   Cliente SVN instalado e acessível via linha de comando (`svn`)

### Instalação Automatizada

```bash
# Linux/macOS
curl -sSL https://raw.githubusercontent.com/tiagotnx/svndiff/main/scripts/install.sh | bash

# Ou baixe manualmente da página de releases
# https://github.com/tiagotnx/svndiff/releases
```

### Compilar e Instalar

```bash
# Clone o repositório
git clone https://github.com/tiagotnx/svndiff
cd svndiff

# Configure o ambiente (instala ferramentas de desenvolvimento)
make setup

# Compile e instale
make build && make install

# Ou compile apenas
make build
```

### Usando Docker

```bash
# Desenvolvimento
docker-compose up svndiff-dev

# Produção
docker run --rm -v $(pwd)/config.yaml:/home/svndiff/config.yaml tiagotnx/svndiff

# Executar testes
docker-compose --profile test up svndiff-test
```

### Instalação Direta

Se o projeto estiver publicado:

```bash
go install github.com/seu-usuario/svndiff@latest
```

## 📝 Configuração

### Arquivo config.yaml

Crie um arquivo `config.yaml` na raiz do seu projeto:

```yaml
# Configuração da Branch A
branchA:
    url: 'https://svn.example.com/project/branches/feature-A'
    revisions:
        - '12345'
        - '12348'
        - '12350'

# Configuração da Branch B
branchB:
    url: 'https://svn.example.com/project/branches/feature-B'
    revisions:
        - '12351'
        - '12355'

# Formato de saída: list, diff ou json
output: 'list'

# Mostrar apenas resumo das diferenças
summarize: true

# Credenciais de autenticação (opcional)
auth:
    user: 'myuser'
    password: 'mypassword'
```

### Variáveis de Ambiente

Você também pode usar variáveis de ambiente prefixadas com `SVNDIFF_`:

```bash
export SVNDIFF_BRANCHA_URL="https://svn.example.com/project/branches/feature-A"
export SVNDIFF_BRANCHB_URL="https://svn.example.com/project/branches/feature-B"
export SVNDIFF_AUTH_USER="myuser"
export SVNDIFF_OUTPUT="diff"
```

## 🎯 Uso

### Uso Básico

```bash
# Usando arquivo de configuração (config.yaml no diretório atual)
svndiff

# Especificando arquivo de configuração
svndiff --config /path/to/config.yaml
```

### Uso com Flags

```bash
# Comparação simples
svndiff \
  --urlA "https://svn.example.com/project/branches/feature-A" \
  --revsA "12345,12348" \
  --urlB "https://svn.example.com/project/branches/feature-B" \
  --revsB "12351" \
  --output diff

# Com autenticação
svndiff \
  --urlA "https://svn.example.com/project/branches/feature-A" \
  --revsA "12345" \
  --urlB "https://svn.example.com/project/branches/feature-B" \
  --revsB "12351" \
  --user "myuser" \
  --password "mypassword" \
  --output json
```

## 📖 Exemplos

### Exemplo 1: Lista Simples de Arquivos

```bash
svndiff --output list
```

**Saída:**

```
=== SVN Diff Comparison ===
Branch A: https://svn.example.com/project/branches/feature-A @ 12350
Branch B: https://svn.example.com/project/branches/feature-B @ 12355

Arquivos modificados (3):
  src/main.go
  README.md
  config/settings.json
```

### Exemplo 2: Diff Unificado Colorido

```bash
svndiff --output diff --summarize=false
```

**Saída:**

```
=== SVN Diff Comparison ===
Branch A: https://svn.example.com/project/branches/feature-A @ 12350
Branch B: https://svn.example.com/project/branches/feature-B @ 12355

Index: src/main.go
===================================================================
--- src/main.go	(revision 12350)
+++ src/main.go	(revision 12355)
@@ -10,7 +10,8 @@
 func main() {
-    fmt.Println("Hello World")
+    fmt.Println("Hello, SVN Diff!")
+    fmt.Println("Version 2.0")
 }
```

### Exemplo 3: Saída JSON

```bash
svndiff --output json
```

**Saída:**

```json
{
    "branchA": {
        "url": "https://svn.example.com/project/branches/feature-A",
        "revisions": ["12345", "12348", "12350"],
        "latest": "12350"
    },
    "branchB": {
        "url": "https://svn.example.com/project/branches/feature-B",
        "revisions": ["12351", "12355"],
        "latest": "12355"
    },
    "changes": [
        {
            "path": "src/main.go",
            "status": "Modified"
        },
        {
            "path": "README.md",
            "status": "Modified"
        },
        {
            "path": "config/settings.json",
            "status": "Added"
        }
    ],
    "totalFiles": 3
}
```

## 🚩 Flags Disponíveis

| Flag          | Tipo     | Descrição                                    | Padrão        |
| ------------- | -------- | -------------------------------------------- | ------------- |
| `--config`    | string   | Caminho para arquivo de configuração         | `config.yaml` |
| `--urlA`      | string   | URL da Branch A                              | -             |
| `--revsA`     | []string | Revisões da Branch A (separadas por vírgula) | -             |
| `--urlB`      | string   | URL da Branch B                              | -             |
| `--revsB`     | []string | Revisões da Branch B (separadas por vírgula) | -             |
| `--user`      | string   | Usuário SVN para autenticação                | -             |
| `--password`  | string   | Senha SVN para autenticação                  | -             |
| `--output`    | string   | Formato de saída (`list`, `diff`, `json`)    | `list`        |
| `--summarize` | bool     | Mostrar apenas resumo das diferenças         | `true`        |

### Precedência de Configuração

A precedência das configurações é (da maior para menor):

1. **Flags de linha de comando**
2. **Variáveis de ambiente**
3. **Arquivo de configuração**
4. **Valores padrão**

## 📊 Formatos de Saída

### `list` (Padrão)

Mostra uma lista simples dos arquivos modificados com status colorido.

### `diff`

Mostra o diff unificado completo com sintaxe colorida:

-   🔵 Azul: Cabeçalhos de arquivo
-   🟣 Roxo: Informações de linha/contexto
-   🟢 Verde: Linhas adicionadas
-   🔴 Vermelho: Linhas removidas
-   🟡 Amarelo: Metadados

### `json`

Retorna um objeto JSON estruturado com:

-   Informações das branches
-   Lista detalhada de mudanças
-   Contadores e metadados

## 🛠️ Desenvolvimento

### Configuração Rápida

```bash
# Clone o repositório
git clone https://github.com/tiagotnx/svndiff
cd svndiff

# Configure o ambiente de desenvolvimento
make setup

# Inicie desenvolvimento com hot reload
make dev
```

### Ferramentas de Desenvolvimento

-   **🧪 Testes**: Cobertura de código completa
-   **🔍 Linting**: golangci-lint configurado
-   **🔥 Hot Reload**: Air para desenvolvimento
-   **🎣 Git Hooks**: Pre-commit e pre-push automáticos
-   **🐳 Docker**: Containers para dev e produção
-   **⚡ VS Code**: Configuração completa com tarefas

### Estrutura do Projeto

```
svndiff/
├── cmd/
│   └── root.go        # Comandos Cobra e configuração CLI
├── internal/
│   ├── app/
│   │   └── differ.go  # Lógica principal de orquestração
│   └── svn/
│       └── client.go  # Wrapper para comandos SVN
├── pkg/
│   └── config/
│       └── config.go  # Estruturas de configuração
├── scripts/           # Scripts de automação
├── .github/
│   └── workflows/     # CI/CD pipelines
├── .vscode/          # Configuração VS Code
├── main.go           # Ponto de entrada
├── config.yaml       # Exemplo de configuração
├── Dockerfile        # Imagem de produção
├── docker-compose.yml # Ambiente de desenvolvimento
└── README.md
```

### Comandos de Desenvolvimento

```bash
# Configurar ambiente
make setup

# Desenvolvimento com hot reload
make dev

# Executar testes
make test
make test-coverage
make test-integration

# Linting e formatação
make lint

# Verificação de segurança
make security

# Build
make build
make build-all

# Docker
make docker-build
make docker-dev
make docker-test

# Instalar git hooks
make install-hooks
```

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/amazing-feature`)
3. Commit suas mudanças (`git commit -m 'Add some amazing feature'`)
4. Push para a branch (`git push origin feature/amazing-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

## 🐛 Reportando Problemas

Se você encontrar bugs ou tiver sugestões, por favor abra uma [issue](https://github.com/seu-usuario/svndiff/issues).

## 📚 Recursos Adicionais

-   [Documentação SVN](https://subversion.apache.org/docs/)
-   [Cobra Framework](https://github.com/spf13/cobra)
-   [Viper Configuration](https://github.com/spf13/viper)
-   [Go Modules](https://golang.org/ref/mod)
