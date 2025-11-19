@echo off
setlocal enabledelayedexpansion
title PikaKaraoke Installer
color 0A

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
    echo Downloading FFmpeg (this may take a minute)...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -OutFile 'ffmpeg.zip'"
    
    if not exist ffmpeg.zip (
        color 0C
        echo Error downloading FFmpeg. Check your internet connection.
        pause
        exit /b 1
    )
    
    echo.
    echo Extracting FFmpeg...
    powershell -NoProfile -Command "Expand-Archive -Path ffmpeg.zip -DestinationPath .\ffmpeg -Force"
    
    if %errorlevel% neq 0 (
        color 0C
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
            color 0E
            echo [WARNING] Failed to add FFmpeg to PATH. Check your permissions.
            color 0A
        )
    )
    
    if "!FOUND!"=="0" (
        color 0C
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
    echo Please wait, this may take a minute...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri '!PYTHON_URL!' -OutFile 'python-installer.exe'"
    
    if not exist python-installer.exe (
        color 0C
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
        color 0C
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
            echo Please wait, this may take a minute...
            powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'chrome_installer.exe'"
            
            if not exist chrome_installer.exe (
                color 0C
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
                color 0E
                echo [WARNING] An error occurred while installing Chrome. Continuing...
                color 0A
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
echo Installing PikaKaraoke (this may take a minute)...
pip install pikaraoke
if %errorlevel% equ 0 (
    echo [OK] PikaKaraoke installed successfully.
) else (
    color 0C
    echo [ERROR] An error occurred while installing PikaKaraoke. Check if Python was installed correctly.
    pause
    exit /b 1
)
echo.

:: 5. Download custom icon
echo Downloading PikaKaraoke icon...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lvmasterrj/win-pikaraoke-installer/main/logo.ico' -OutFile 'pikaraoke.ico'"
if exist pikaraoke.ico (
    echo [OK] Icon downloaded successfully.
) else (
    color 0E
    echo [WARNING] Failed to download the icon. The shortcut will use the default icon.
    color 0A
)
echo.

:: 6. Create desktop shortcut
set /p criarAtalho="Do you want to create a desktop shortcut for PikaKaraoke? (Y/N): "
if /I "%criarAtalho%"=="Y" (
    echo Creating desktop shortcut...
    call :CreateShortcut
) else (
    echo Shortcut not created.
)
echo.

color 0A
echo ===============================================
echo   Installation complete! Have fun singing!
echo ===============================================
color 07
pause
exit /b 0

:CreateShortcut
setlocal enabledelayedexpansion
set "SCRIPT=%temp%\create_shortcut.ps1"
(
    echo $ws = New-Object -ComObject WScript.Shell
    echo $sc = $ws.CreateShortcut('%USERPROFILE%\Desktop\PikaKaraoke.lnk'
    echo $sc.TargetPath = 'cmd.exe'
    echo $sc.Arguments = '/c pikaraoke'
    echo $sc.WorkingDirectory = '%USERPROFILE%'
    echo if (Test-Path 'pikaraoke.ico'^) { $sc.IconLocation = (Get-Item 'pikaraoke.ico'^).FullName }
    echo $sc.Save(^)
) > "%SCRIPT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
del "%SCRIPT%" >nul 2>nul
echo [OK] Shortcut created successfully.
endlocal
goto :EOF