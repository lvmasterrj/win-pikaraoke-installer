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
    powershell -Command "Invoke-WebRequest -Uri https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip -OutFile ffmpeg.zip"
    
    if not exist "ffmpeg.zip" (
        echo Error downloading FFmpeg. Check your internet connection.
        pause
        exit /b 1
    )
    
    powershell -Command "Expand-Archive -Path ffmpeg.zip -DestinationPath c:\ffmpeg -Force"
    
    if not exist "c:\ffmpeg\ffmpeg-*" (
        echo Error extracting FFmpeg.
        pause
        exit /b 1
    )
    
    for /d %%i in ("c:\ffmpeg\ffmpeg-*") do (
        set "FFMPEG_PATH=%%i\bin"
        setx PATH "!FFMPEG_PATH!;%PATH%"
        if %errorlevel% equ 0 (
            echo FFmpeg installed and added to PATH successfully.
        ) else (
            echo Warning: Failed to add FFmpeg to PATH. Check your permissions.
        )
        goto ffmpeg_done
    )
    :ffmpeg_done
    del ffmpeg.zip >nul 2>nul
) else (
    echo FFmpeg is already installed.
)
echo.

:: 2. Check Python
echo Checking Python...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Python is already installed.
) else (
    echo Python not found. Installing...

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
    powershell -Command "Invoke-WebRequest -Uri !PYTHON_URL! -OutFile python-installer.exe"
    if %errorlevel% neq 0 (
        echo Error downloading Python. Check your internet connection.
        pause
        exit /b 1
    )
    
    start /wait python-installer.exe /passive InstallAllUsers=1 PrependPath=1
    if %errorlevel% equ 0 (
        echo Python installed successfully.
        del python-installer.exe >nul 2>nul
    ) else (
        echo Error installing Python. Check your permissions.
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
            echo Downloading and installing Google Chrome...
            powershell -Command "Invoke-WebRequest -Uri https://dl.google.com/chrome/install/latest/chrome_installer.exe -OutFile chrome_installer.exe"
            if %errorlevel% neq 0 (
                echo Error downloading Chrome. Check your internet connection.
                pause
                exit /b 1
            )
            
            start /wait chrome_installer.exe /silent /install
            if %errorlevel% equ 0 (
                echo Google Chrome installed successfully.
                del chrome_installer.exe >nul 2>nul
            ) else (
                echo Warning: An error occurred while installing Chrome. Continuing...
                del chrome_installer.exe >nul 2>nul
            )
        ) else (
            echo Chrome installation skipped.
        )
    ) else (
        echo Google Chrome is already installed.
    )
) else (
    echo Google Chrome is already installed.
)
echo.

:: 4. Install PikaKaraoke
echo Installing PikaKaraoke via pip...
pip install --upgrade pip >nul 2>&1
pip install pikaraoke
if %errorlevel% equ 0 (
    echo PikaKaraoke installed successfully.
) else (
    echo An error occurred while installing PikaKaraoke. Check if Python was installed correctly.
    pause
    exit /b 1
)
echo.

:: 5. Download custom icon
echo Downloading PikaKaraoke icon...
powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/lvmasterrj/win-pikaraoke-installer/main/logo.ico -OutFile pikaraoke.ico"
if exist pikaraoke.ico (
    echo Icon downloaded successfully.
) else (
    echo Warning: Failed to download the icon. The shortcut will use the default icon.
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
    $Shortcut.Save()"
    if %errorlevel% equ 0 (
        echo Shortcut created successfully.
    ) else (
        echo Warning: An error occurred while creating the shortcut.
    )
) else (
    echo Shortcut not created.
)
echo.

echo ===============================================
echo   Installation complete! Have fun singing!
echo ===============================================
pause