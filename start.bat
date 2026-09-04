@echo off
REM ============================================
REM Script para iniciar o projeto WhatsApp Clone
REM ============================================

echo ==========================================
echo   WhatsApp Clone - Firebase Setup
echo ==========================================

REM Vai para o diretorio do projeto
cd /d "%~dp0"

REM Verifica Java
echo Verificando Java...
java -version 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Java nao encontrado!
    echo Instale o Java 21+ ou execute: winget install --id Microsoft.OpenJDK.21 -e
    pause
    exit /b 1
)

REM Verifica Firebase CLI
where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] Firebase CLI nao encontrado. Instalando...
    call npm install -g firebase-tools
)

REM Pergunta o que fazer
echo.
echo O que voce deseja fazer?
echo 1 - Iniciar emuladores do Firebase
echo 2 - Apenas rodar o app Flutter (assume emulador ja rodando)
echo 3 - Compilar o projeto (flutter analyze)
echo.
set /p opcao="Opcao: "

if "%opcao%"=="1" (
    echo Iniciando emuladores Firebase...
    firebase emulators:start --only auth,firestore,storage --project whatsapp-clone-demo
) else if "%opcao%"=="2" (
    echo Iniciando app Flutter...
    flutter run
) else if "%opcao%"=="3" (
    echo Analisando projeto...
    flutter analyze
) else (
    echo Opcao invalida!
)

pause