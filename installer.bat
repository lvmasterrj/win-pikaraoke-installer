@echo off
setlocal enabledelayedexpansion
title Instalador do PikaKaraoke

echo ==============================================
echo     Instalador do PikaKaraoke para Windows
echo ==============================================
echo.

:: 1. Verificar FFmpeg
echo Verificando FFmpeg...
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo FFmpeg nao encontrado. Instalando FFmpeg...
    powershell -Command "Invoke-WebRequest -Uri https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip -OutFile ffmpeg.zip"
    powershell -Command "Expand-Archive ffmpeg.zip -DestinationPath .\ffmpeg"
    set "FFMPEG_PATH=%cd%\ffmpeg\ffmpeg-*-essentials_build\bin"
    for /d %%i in ("%cd%\ffmpeg\ffmpeg-*") do set "FFMPEG_PATH=%%i\bin"
    setx PATH "!FFMPEG_PATH!;%PATH%"
    echo FFmpeg instalado e adicionado ao PATH com sucesso.
) else (
    echo FFmpeg ja está instalado.
)
echo.

:: 2. Verificar Python
echo Verificando Python...
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python não encontrado. Detectando arquitetura do Windows...

    set "PYTHON_URL="
    set "ARCHITECTURE=%PROCESSOR_ARCHITECTURE%"

    if /I "%ARCHITECTURE%"=="AMD64" (
        set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9-amd64.exe"
    ) else if /I "%ARCHITECTURE%"=="ARM64" (
        set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9-arm64.exe"
    ) else (
        set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9.exe"
    )

    echo Baixando Python 3.13.9 para arquitetura %ARCHITECTURE%...
    powershell -Command "Invoke-WebRequest -Uri !PYTHON_URL! -OutFile python-installer.exe"
    start /wait python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    echo Python instalado e adicionado ao PATH com sucesso.
) else (
    echo Python já está instalado.
)
echo.

:: 3. Verificar Google Chrome
echo Verificando Google Chrome...
if not exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set /p installChrome="Google Chrome não encontrado. Deseja instalar? (S/N): "
    if /I "%installChrome%"=="S" (
        echo Baixando e instalando Google Chrome...
        powershell -Command "Invoke-WebRequest -Uri https://dl.google.com/chrome/install/latest/chrome_installer.exe -OutFile chrome_installer.exe"
        start /wait chrome_installer.exe /silent /install
        echo Google Chrome instalado com sucesso.
    ) else (
        echo Instalação do Chrome ignorada.
    )
) else (
    echo Google Chrome já está instalado.
)
echo.

:: 4. Instalar PikaKaraoke
echo Instalando PikaKaraoke via pip...
pip install pikaraoke
if %errorlevel% equ 0 (
    echo PikaKaraoke instalado com sucesso.
) else (
    echo Houve um erro ao instalar o PikaKaraoke.
)
echo.

:: 5. Baixar ícone personalizado
echo Baixando ícone do PikaKaraoke...
powershell -Command "Invoke-WebRequest -Uri https://github.com/lvmasterrj/win-pikaraoke-installer/blob/main/logo.ico -OutFile pikaraoke.ico"
if exist pikaraoke.ico (
    echo Ícone baixado com sucesso.
) else (
    echo Falha ao baixar o ícone. O atalho usará o ícone padrão.
)
echo.

:: 6. Criar atalho na área de trabalho
set /p criarAtalho="Deseja criar um atalho na area de trabalho para o PikaKaraoke? (S/N): "
if /I "%criarAtalho%"=="S" (
    echo Criando atalho na area de trabalho...
    powershell -Command ^
    "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USERPROFILE%\Desktop\PikaKaraoke.lnk'); ^
    $s.TargetPath='pikaraoke'; ^
    if (Test-Path '%cd%\pikaraoke.ico') { $s.IconLocation='%cd%\pikaraoke.ico' }; ^
    $s.Save()"
    echo Atalho criado com sucesso.
) else (
    echo Atalho não criado.
)
echo.

echo ===============================================
echo   Instalação concluída! Divirta-se cantando!
echo ===============================================
pause