# ============================================
# Script para iniciar emuladores do Firebase
# ============================================
# Uso: .\start_emulators.ps1

$ErrorActionPreference = "Stop"

# Cores para output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Reset = "`e[0m"

Write-Host "${Yellow}========================================${Reset}"
Write-Host "${Yellow}  Firebase Emulators - WhatsApp Clone  ${Reset}"
Write-Host "${Yellow}========================================${Reset}"

# Verifica Java
$javaCheck = & java -version 2>&1
$javaVersion = ($javaCheck | Select-String -Pattern 'version "(.+?)"').Matches.Groups[1].Value
Write-Host "${Green}Java detectado: $javaVersion${Reset}"

# Vai para o diretório do projeto
Set-Location -Path $PSScriptRoot

# Verifica Firebase CLI
try {
    $firebaseVersion = & firebase --version
    Write-Host "${Green}Firebase CLI: $firebaseVersion${Reset}"
} catch {
    Write-Host "${Red}Firebase CLI nao encontrado. Instalando...${Reset}"
    npm install -g firebase-tools
}

# Inicia os emuladores
Write-Host "${Yellow}Iniciando emuladores...${Reset}"
firebase emulators:start --only auth,firestore,storage --project whatsapp-clone-demo