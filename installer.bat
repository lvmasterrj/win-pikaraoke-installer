@echo off
setlocal enabledelayedexpansion
title PiKaraoke Installer
:: Created by lvmasterrj - https://github.com/lvmasterrj

echo ==============================================
echo  PiKaraoke Installer for Windows
echo ==============================================
echo.

:: 0. Check if PiKaraoke is already installed
pip show pikaraoke >nul 2>&1
if !errorlevel! equ 0 (
  echo PiKaraoke is already installed.
  set /p continueInstall="Do you want to continue with the installation anyway? (Y/N): "
  
  if /I "!continueInstall!"=="Y" (
    echo Continuing with installation...
    ) else (
    echo Installation cancelled. Exiting installer...
    pause
    exit /b 0
  )
)
echo.

:: 1. Check FFmpeg
echo Checking FFmpeg...
where ffmpeg >nul 2>nul
if !errorlevel! equ 0 (
  echo FFmpeg is already installed.
  timeout /t 2 /nobreak >nul
  ) else (
  echo FFmpeg not found. Downloading FFmpeg...
  
  powershell -Command "Invoke-WebRequest -Uri https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip -OutFile ffmpeg.zip"
  
  if not exist "ffmpeg.zip" (
    echo Error downloading FFmpeg. Check your internet connection.
    pause
    exit /b 1
  )
  
  echo Extracting FFmpeg...
  powershell -Command "Expand-Archive -Path ffmpeg.zip -DestinationPath %SystemDrive%\ffmpeg -Force"
  
  if not exist "%SystemDrive%\ffmpeg\ffmpeg-*" (
    echo Error extracting FFmpeg.
    pause
    exit /b 1
  )
  
  for /d %%i in ("%SystemDrive%\ffmpeg\ffmpeg-*") do (
    set "FFMPEG_PATH=%%i\bin"
    setx PATH "%PATH%;!FFMPEG_PATH!"
    if !errorlevel! equ 0 (
      echo FFmpeg installed and added to PATH successfully.
      timeout /t 2
      ) else (
      echo Warning: Failed to add FFmpeg to PATH. Check your permissions.
      timeout /t 2
    )
    goto ffmpeg_done
  )
  :ffmpeg_done
  del ffmpeg.zip >nul 2>nul
)
echo.

:: 2. Check Python
echo Checking Python...
python --version >nul 2>&1
if !errorlevel! equ 0 (
  echo Python is already installed.
  timeout /t 2 /nobreak >nul
  ) else (
  echo Python not found.
  
  set "PYTHON_URL="
  set "ARCHITECTURE=%PROCESSOR_ARCHITECTURE%"
  
  if /I "!ARCHITECTURE!"=="AMD64" (
    set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9-amd64.exe"
    ) else if /I "!ARCHITECTURE!"=="ARM64" (
    set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9-arm64.exe"
    ) else (
    set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9.exe"
  )
  
  echo Downloading Python 3.13.9 for architecture !ARCHITECTURE! ...
  timeout /t 2 /nobreak >nul
  powershell -Command "Invoke-WebRequest -Uri !PYTHON_URL! -OutFile python-installer.exe"
  
  if not exist "python-installer.exe" (
    echo Error downloading Python. Check your internet connection.
    pause
    exit /b 1
  )
  
  echo Installing Python 3.13.9...
  start /wait python-installer.exe /passive PrependPath=1 Include_pip=1 Include_tcltk=1 Include_launcher=1 Include_test=0 Include_symbols=1 Include_debug=1 Shortcuts=1
  
  timeout /t 5 /nobreak >nul
  
  set "PYTHON_PATH="
  
  if exist "%ProgramFiles%\Python313\python.exe" (
    echo Python installed successfully.
    set "PYTHON_PATH=%ProgramFiles%\Python313\python.exe"
    del python-installer.exe >nul 2>nul
    ) else if exist "%ProgramFiles(x86)%\Python313-32\python.exe" (
    echo Python installed successfully.
    set "PYTHON_PATH=%ProgramFiles(x86)%\Python313-32\python.exe"
    del python-installer.exe >nul 2>nul
    ) else if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" (
    echo Python installed successfully.
    set "PYTHON_PATH=%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    del python-installer.exe >nul 2>nul
    ) else (
    echo Warning: Python may not have been installed correctly. Continuing...
    del python-installer.exe >nul 2>nul
  )
)
echo.

:: 3. Checking Google Chrome...
echo Checking Google Chrome...
set "chromePath="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "chromePath=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "chromePath=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "chromePath=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"

if defined chromePath (
  echo Google Chrome is already installed.
  ) else (
  set /p installChrome="Google Chrome not found. Do you want to install it? (Y/N): "
  if /I "!installChrome!"=="Y" (
    echo Downloading and installing Google Chrome...
    powershell -Command "Invoke-WebRequest -Uri https://dl.google.com/chrome/install/latest/chrome_installer.exe -OutFile chrome_installer.exe"
    if !errorlevel! neq 0 (
      echo Error downloading Chrome. Check your internet connection.
      pause
      ) else (
      start /wait chrome_installer.exe /silent /install
      if !errorlevel! equ 0 (
        echo Google Chrome installed successfully.
        del chrome_installer.exe >nul 2>nul
        ) else (
        echo Warning: An error occurred while installing Chrome. Proceeding without Chrome...
        del chrome_installer.exe >nul 2>nul
      )
    )
    ) else (
    echo Chrome installation skipped.
  )
)

echo.

:: 4. Installing Deno...
echo Checking Deno...

where deno >nul 2>nul
if !errorlevel! equ 0 (
  echo Deno is already installed.
  timeout /t 2 /nobreak >nul
  ) else (
  echo Deno not found. Installing Deno...
  powershell -Command "iwr https://deno.land/install.ps1 -useb | iex"
  
  if !errorlevel! equ 0 (
    echo Deno installed successfully.
    timeout /t 2
    ) else (
    echo Warning: An error occurred while installing Deno. Continuing...
    timeout /t 2
  )
)
echo.

:: 5. Installing PikaKaraoke...
echo Installing PikaKaraoke via pip...

if not defined PYTHON_PATH (
  set "PYTHON_PATH=python"
)

"%PYTHON_PATH%" -m pip install --upgrade pip >nul 2>&1
if !errorlevel! neq 0 (
  echo Warning: pip upgrade had an issue but continuing...
)

"%PYTHON_PATH%" -m pip install pikaraoke
if !errorlevel! equ 0 (
  echo PikaKaraoke installed successfully.
  echo Installing yt-dlp-ejs python package...
  
  "%PYTHON_PATH%" -m pip install -U "yt-dlp[default]"
  if !errorlevel! equ 0 (
    echo yt-dlp-ejs installed successfully.
    ) else (
    echo Warning: An error occurred while installing yt-dlp-ejs. Continuing...
  )
  ) else (
  echo Warning: An error occurred while installing PikaKaraoke. Continuing...
  echo PikaKaraoke exit code: !errorlevel!
)
echo.

echo ===============================================
echo  How to start PiKaraoke
echo.
echo - Open the Command Prompt (type "cmd" on the search bar)
echo - Type "pikaraoke" and enter
echo - Enjoy!
echo ===============================================
echo.

:: 6. Creating shortcut
set /p createShortcut="Do you want to create a shortcut for PiKaraoke on desktop? (Y/N): "
if /I "!createShortcut!"=="Y" (
  echo Checking for PikaKaraoke icon...
  if exist logo.ico (
    echo Icon found locally.
    ) else (
    echo Downloading PikaKaraoke icon...
    powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/lvmasterrj/win-pikaraoke-installer/main/logo.ico -OutFile logo.ico"
    if exist logo.ico (
      echo Icon downloaded successfully.
      ) else (
      echo Warning: Failed to download the icon. The shortcut will use the default icon.
    )
  )
  echo.
  
  echo Creating desktop shortcut...
  
  powershell -NoLogo -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Desktop = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'),'PiKaraoke.lnk'); $Shortcut = $WshShell.CreateShortcut($Desktop); $Shortcut.TargetPath = 'cmd.exe'; $Shortcut.Arguments = '/c pikaraoke'; $Shortcut.WorkingDirectory = [Environment]::GetFolderPath('UserProfile'); if (Test-Path \"$pwd\logo.ico\") { $Shortcut.IconLocation = \"$pwd\logo.ico\" }; $Shortcut.Save()"
  
  if !errorlevel! equ 0 (
    echo Shortcut created successfully.
    ) else (
    echo Warning: An error occurred while creating the shortcut.
    echo Shortcut exit code: !errorlevel!
  )
)
echo.

echo ===============================================
echo  Installation complete! Have fun singing!
echo ===============================================

pause
