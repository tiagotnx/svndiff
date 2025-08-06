# Script PowerShell para executar testes de integração
# Uso: .\scripts\integration-tests.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔧 Executando testes de integração para svndiff..." -ForegroundColor Cyan
Write-Host ""

# Verificar se o SVN está disponível
try {
    $svnVersion = & svn --version --quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SVN está disponível: $svnVersion" -ForegroundColor Green
    } else {
        throw "SVN não funcionou"
    }
} catch {
    Write-Host "❌ SVN não está instalado ou não está no PATH" -ForegroundColor Red
    Write-Host "💡 Tentando adicionar TortoiseSVN ao PATH..." -ForegroundColor Yellow
    $env:PATH += ";C:\Program Files\TortoiseSVN\bin"
    try {
        $svnVersion = & svn --version --quiet 2>&1
        Write-Host "✅ SVN está disponível: $svnVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao localizar SVN" -ForegroundColor Red
        exit 1
    }
}

# Compilar a aplicação
Write-Host "🏗️  Compilando aplicação..." -ForegroundColor Yellow
& go build -o .\build\svndiff.exe .

if (-not (Test-Path ".\build\svndiff.exe")) {
    Write-Host "❌ Falha ao compilar a aplicação" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Aplicação compilada com sucesso" -ForegroundColor Green

# Teste 1: Verificar help
Write-Host ""
Write-Host "📋 Teste 1: Comando de ajuda" -ForegroundColor Cyan
$output = & .\build\svndiff.exe --help 2>&1
if ($LASTEXITCODE -eq 0 -and $output -match "svndiff") {
    Write-Host "✅ Comando de ajuda funcionou" -ForegroundColor Green
} else {
    Write-Host "❌ Comando de ajuda falhou" -ForegroundColor Red
    Write-Host "Saída: $output" -ForegroundColor Red
    exit 1
}

# Teste 2: Verificar versão
Write-Host ""
Write-Host "📋 Teste 2: Comando de versão" -ForegroundColor Cyan
$output = & .\build\svndiff.exe --version 2>&1
if ($LASTEXITCODE -eq 0 -and $output -match "svndiff") {
    Write-Host "✅ Comando de versão funcionou" -ForegroundColor Green
} else {
    Write-Host "❌ Comando de versão falhou" -ForegroundColor Red
    Write-Host "Saída: $output" -ForegroundColor Red
    exit 1
}

# Teste 3: Verificar validação de configuração
Write-Host ""
Write-Host "📋 Teste 3: Validação de configuração" -ForegroundColor Cyan
$output = & .\build\svndiff.exe --urlA "" --urlB "test" --revsA "123" --revsB "124" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✅ Validação de configuração funcionou corretamente" -ForegroundColor Green
} else {
    Write-Host "❌ Validação de configuração falhou - deveria ter retornado erro" -ForegroundColor Red
    Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Saída: $output" -ForegroundColor Red
    exit 1
}

# Teste 3: Tratamento de erro com URL inválida
Write-Host ""
Write-Host "📋 Teste 4: Tratamento de erro de conectividade" -ForegroundColor Cyan
$output = & .\build\svndiff.exe --urlA "https://invalid.example.com/svn" --urlB "https://invalid.example.com/svn2" --revsA "123" --revsB "124" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✅ Tratamento de erro funcionou corretamente" -ForegroundColor Green
} else {
    Write-Host "❌ Erro não foi tratado corretamente" -ForegroundColor Red
    Write-Host "Saída: $output" -ForegroundColor Red
    exit 1
}

# Teste 4: Carregamento de arquivo de configuração
Write-Host ""
Write-Host "📋 Teste 5: Carregamento de arquivo de configuração" -ForegroundColor Cyan

$configContent = @"
urlA: "https://invalid.example.com/svn/branchA"
urlB: "https://invalid.example.com/svn/branchB"
revsA: ["123"]
revsB: ["124"]
output: "list"
summarize: true
"@

$configContent | Out-File -FilePath "test-config.yaml" -Encoding UTF8

$output = & .\build\svndiff.exe --config test-config.yaml 2>&1
if ($LASTEXITCODE -ne 0 -and $output -match "erro|falha|conectar") {
    Write-Host "✅ Carregamento de arquivo de configuração funcionou" -ForegroundColor Green
} else {
    Write-Host "❌ Carregamento de arquivo de configuração falhou" -ForegroundColor Red
    Write-Host "Saída: $output" -ForegroundColor Red
    Remove-Item -Path "test-config.yaml" -Force -ErrorAction SilentlyContinue
    exit 1
}

# Limpeza
Remove-Item -Path "test-config.yaml" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "🎉 Todos os testes de integração passaram!" -ForegroundColor Green
Write-Host "📋 Resumo dos testes:" -ForegroundColor Cyan
Write-Host "  ✅ Comando de ajuda" -ForegroundColor Green
Write-Host "  ✅ Comando de versão" -ForegroundColor Green
Write-Host "  ✅ Validação de configuração" -ForegroundColor Green
Write-Host "  ✅ Tratamento de erro de conectividade" -ForegroundColor Green
Write-Host "  ✅ Carregamento de arquivo de configuração" -ForegroundColor Green
