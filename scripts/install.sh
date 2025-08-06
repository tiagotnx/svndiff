#!/bin/bash

# Script de instalação automatizada do svndiff
# Uso: curl -sSL https://raw.githubusercontent.com/tiagotnx/svndiff/main/scripts/install.sh | bash

set -e

# Configurações
REPO="tiagotnx/svndiff"
BINARY_NAME="svndiff"
INSTALL_DIR="/usr/local/bin"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detectar OS e arquitetura
detect_platform() {
    local os
    local arch

    # Detectar OS
    case "$(uname -s)" in
        Linux*)     os="linux";;
        Darwin*)    os="darwin";;
        CYGWIN*|MINGW*|MSYS*) os="windows";;
        *)          log_error "OS não suportado: $(uname -s)"; exit 1;;
    esac

    # Detectar arquitetura
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64";;
        arm64|aarch64)  arch="arm64";;
        *)              log_error "Arquitetura não suportada: $(uname -m)"; exit 1;;
    esac

    echo "${os}-${arch}"
}

# Obter a última versão do GitHub
get_latest_version() {
    local latest_url="https://api.github.com/repos/${REPO}/releases/latest"

    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$latest_url" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$latest_url" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
    else
        log_error "curl ou wget é necessário para fazer download"
        exit 1
    fi
}

# Fazer download do binário
download_binary() {
    local version="$1"
    local platform="$2"
    local extension=""

    if [[ "$platform" == *"windows"* ]]; then
        extension=".zip"
    else
        extension=".tar.gz"
    fi

    local download_url="https://github.com/${REPO}/releases/download/${version}/${BINARY_NAME}-${platform}${extension}"
    local temp_file="/tmp/${BINARY_NAME}-${platform}${extension}"

    log_info "Fazendo download de $download_url"

    if command -v curl >/dev/null 2>&1; then
        curl -sSL -o "$temp_file" "$download_url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$temp_file" "$download_url"
    else
        log_error "curl ou wget é necessário para fazer download"
        exit 1
    fi

    echo "$temp_file"
}

# Extrair e instalar binário
install_binary() {
    local archive_file="$1"
    local platform="$2"
    local binary_name="$BINARY_NAME"

    if [[ "$platform" == *"windows"* ]]; then
        binary_name="${BINARY_NAME}.exe"
    fi

    # Criar diretório temporário
    local temp_dir
    temp_dir=$(mktemp -d)

    # Extrair arquivo
    if [[ "$archive_file" == *.zip ]]; then
        unzip -q "$archive_file" -d "$temp_dir"
    else
        tar -xzf "$archive_file" -C "$temp_dir"
    fi

    # Encontrar o binário
    local binary_path
    binary_path=$(find "$temp_dir" -name "$binary_name" -type f | head -1)

    if [[ -z "$binary_path" ]]; then
        log_error "Binário não encontrado no arquivo baixado"
        exit 1
    fi

    # Verificar se precisa de sudo
    local use_sudo=""
    if [[ ! -w "$INSTALL_DIR" ]]; then
        use_sudo="sudo"
        log_warning "Permissões de root necessárias para instalar em $INSTALL_DIR"
    fi

    # Criar diretório de instalação se não existir
    $use_sudo mkdir -p "$INSTALL_DIR"

    # Copiar binário
    $use_sudo cp "$binary_path" "$INSTALL_DIR/$BINARY_NAME"
    $use_sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"

    # Limpeza
    rm -rf "$temp_dir" "$archive_file"

    log_success "svndiff instalado em $INSTALL_DIR/$BINARY_NAME"
}

# Verificar instalação
verify_installation() {
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        local version
        version=$("$BINARY_NAME" --version 2>/dev/null || echo "unknown")
        log_success "Instalação verificada. Versão: $version"

        log_info "Para usar o svndiff, execute:"
        echo "  $BINARY_NAME --help"

        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            log_warning "$INSTALL_DIR não está no PATH. Adicione-o ao seu .bashrc ou .zshrc:"
            echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
        fi
    else
        log_error "Instalação falhou. $BINARY_NAME não foi encontrado no PATH"
        exit 1
    fi
}

# Função principal
main() {
    log_info "🚀 Instalando svndiff..."

    # Verificar dependências
    if ! command -v tar >/dev/null 2>&1; then
        log_error "tar é necessário mas não está instalado"
        exit 1
    fi

    if ! command -v unzip >/dev/null 2>&1 && [[ "$(detect_platform)" == *"windows"* ]]; then
        log_error "unzip é necessário mas não está instalado"
        exit 1
    fi

    # Detectar plataforma
    local platform
    platform=$(detect_platform)
    log_info "Plataforma detectada: $platform"

    # Obter última versão
    local version
    version=$(get_latest_version)
    log_info "Última versão: $version"

    # Download
    local archive_file
    archive_file=$(download_binary "$version" "$platform")

    # Instalar
    install_binary "$archive_file" "$platform"

    # Verificar
    verify_installation

    log_success "🎉 svndiff instalado com sucesso!"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
