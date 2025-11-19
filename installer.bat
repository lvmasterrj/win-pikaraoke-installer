@echo off
setlocal enabledelayedexpansion
title PikaKaraoke Installer

echo ==============================================
echo     PikaKaraoke Installer for Windows
echo ==============================================
echo.

:: 1. Check FFmpeg
echo Checking FFmpeg...
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo FFmpeg not found. Installing FFmpeg...
    echo.
    powershell -Command "^
    $ProgressPreference = 'Continue'; ^
    Write-Host 'Downloading FFmpeg (this may take a minute)...' -ForegroundColor Cyan; ^
    Invoke-WebRequest -Uri 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -OutFile 'ffmpeg.zip' -Verbose; ^
    Write-Host 'Download complete!' -ForegroundColor Green"
    
    if not exist ffmpeg.zip (
        echo Error downloading FFmpeg. Check your internet connection.
        pause
        exit /b 1
    )
    
    echo.
    echo Extracting FFmpeg...
    powershell -Command "^
    Write-Host 'Extracting files...' -ForegroundColor Cyan; ^
    Expand-Archive -Path ffmpeg.zip -DestinationPath .\ffmpeg -Force; ^
    Write-Host 'Extraction complete!' -ForegroundColor Green"
    
    if %errorlevel% neq 0 (
        echo Error extracting FFmpeg.
        pause
        exit /b 1
    )
    
    echo.
    echo Adding FFmpeg to PATH...
    setlocal enabledelayedexpansion
    set "FOUND=0"
    for /d %%i in ("%cd%\ffmpeg\ffmpeg-*-essentials_build") do (
        set "FFMPEG_PATH=%%i\bin"
        setx PATH "!FFMPEG_PATH!;%PATH%"
        set "FOUND=1"
        if !ERRORLEVEL! equ 0 (
            echo [OK] FFmpeg installed and added to PATH successfully.
        ) else (
            echo [WARNING] Failed to add FFmpeg to PATH. Check your permissions.
        )
    )
    
    if "!FOUND!"=="0" (
        echo [ERROR] Could not find FFmpeg bin directory after extraction.
        pause
        exit /b 1
    )
    
    del ffmpeg.zip >nul 2>nul
) else (
    echo [OK] FFmpeg is already installed.
)
echo.

:: 2. Check Python
echo Checking Python...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python is already installed.
) else (
    echo Python not found. Installing...
    echo.

    set "PYTHON_URL="
    set "ARCHITECTURE=%PROCESSOR_ARCHITECTURE%"

    if /I "%ARCHITECTURE%"=="AMD64" (
        set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9-amd64.exe"
    ) else if /I "%ARCHITECTURE%"=="ARM64" (
        set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9-arm64.exe"
    ) else (
        set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9.exe"
    )

    echo Downloading Python 3.13.9 for architecture %ARCHITECTURE%...
    powershell -Command "^
    $ProgressPreference = 'Continue'; ^
    Write-Host 'Downloading Python (this may take a minute)...' -ForegroundColor Cyan; ^
    Invoke-WebRequest -Uri '!PYTHON_URL!' -OutFile 'python-installer.exe' -Verbose; ^
    Write-Host 'Download complete!' -ForegroundColor Green"
    
    if not exist python-installer.exe (
        echo [ERROR] Error downloading Python. Check your internet connection.
        pause
        exit /b 1
    )
    
    echo.
    echo Installing Python (this may take a few minutes)...
    start /wait python-installer.exe /passive InstallAllUsers=1 PrependPath=1
    if %errorlevel% equ 0 (
        echo [OK] Python installed successfully.
        del python-installer.exe >nul 2>nul
    ) else (
        echo [ERROR] Error installing Python. Check your permissions.
        pause
        exit /b 1
    )
)
echo.

:: 3. Check Google Chrome
echo Checking Google Chrome...
if not exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    if not exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
        set /p installChrome="Google Chrome not found. Do you want to install it? (Y/N): "
        if /I "%installChrome%"=="Y" (
            echo.
            echo Downloading and installing Google Chrome...
            powershell -Command "^
            $ProgressPreference = 'Continue'; ^
            Write-Host 'Downloading Chrome (this may take a minute)...' -ForegroundColor Cyan; ^
            Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'chrome_installer.exe' -Verbose; ^
            Write-Host 'Download complete!' -ForegroundColor Green"
            
            if not exist chrome_installer.exe (
                echo [ERROR] Error downloading Chrome. Check your internet connection.
                pause
                exit /b 1
            )
            
            echo.
            echo Installing Chrome (this may take a minute)...
            start /wait chrome_installer.exe /silent /install
            if %errorlevel% equ 0 (
                echo [OK] Google Chrome installed successfully.
                del chrome_installer.exe >nul 2>nul
            ) else (
                echo [WARNING] An error occurred while installing Chrome. Continuing...
                del chrome_installer.exe >nul 2>nul
            )
        ) else (
            echo Chrome installation skipped.
        )
    ) else (
        echo [OK] Google Chrome is already installed.
    )
) else (
    echo [OK] Google Chrome is already installed.
)
echo.

:: 4. Install PikaKaraoke
echo Installing PikaKaraoke via pip...
pip install --upgrade pip >nul 2>&1
echo.
powershell -Command "^
Write-Host 'Installing PikaKaraoke (this may take a minute)...' -ForegroundColor Cyan"
pip install pikaraoke
if %errorlevel% equ 0 (
    echo [OK] PikaKaraoke installed successfully.
) else (
    echo [ERROR] An error occurred while installing PikaKaraoke. Check if Python was installed correctly.
    pause
    exit /b 1
)
echo.

:: 5. Download custom icon
echo Downloading PikaKaraoke icon...
powershell -Command "^
$ProgressPreference = 'Continue'; ^
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lvmasterrj/win-pikaraoke-installer/main/logo.ico' -OutFile 'pikaraoke.ico' -Verbose"
if exist pikaraoke.ico (
    echo [OK] Icon downloaded successfully.
) else (
    echo [WARNING] Failed to download the icon. The shortcut will use the default icon.
)
echo.

:: 6. Create desktop shortcut
set /p criarAtalho="Do you want to create a desktop shortcut for PikaKaraoke? (Y/N): "
if /I "%criarAtalho%"=="Y" (
    echo Creating desktop shortcut...
    powershell -Command ^
    "$WshShell = New-Object -COM WScript.Shell; ^
    $Desktop = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'PikaKaraoke.lnk'); ^
    $Shortcut = $WshShell.CreateShortcut($Desktop); ^
    $Shortcut.TargetPath = 'cmd.exe'; ^
    $Shortcut.Arguments = '/c pikaraoke'; ^
    $Shortcut.WorkingDirectory = [Environment]::GetFolderPath('UserProfile'); ^
    if (Test-Path '%cd%\pikaraoke.ico') { $Shortcut.IconLocation = '%cd%\pikaraoke.ico' }; ^
    $Shortcut.Save(); ^
    Write-Host '[OK] Shortcut created successfully.' -ForegroundColor Green"
) else (
    echo Shortcut not created.
)
echo.

echo.
powershell -Command "^
Write-Host '===============================================' -ForegroundColor Green; ^
Write-Host '   Installation complete! Have fun singing!   ' -ForegroundColor Green; ^
Write-Host '===============================================' -ForegroundColor Green"
pause