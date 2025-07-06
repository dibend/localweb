@echo off
setlocal enabledelayedexpansion

:: OpenSSL Download Script for Windows 11
:: Downloads OpenSSL from official FireDaemon source
:: Author: Automated Script Generator
:: Version: 1.0

title OpenSSL Downloader for Windows 11

echo.
echo ==========================================
echo  OpenSSL Download Script for Windows 11
echo ==========================================
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: This script is not running as administrator.
    echo Some operations may fail. Consider running as administrator.
    echo.
    pause
)

:: Create download directory
set "DOWNLOAD_DIR=%~dp0OpenSSL_Downloads"
if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
    echo Created download directory: %DOWNLOAD_DIR%
)

:: OpenSSL version information
set "OPENSSL_VERSION=3.5.1"
set "INSTALLER_URL=https://download.firedaemon.com/FireDaemon-OpenSSL/FireDaemon-OpenSSL-x64-3.5.1.exe"
set "ZIP_URL=https://download.firedaemon.com/FireDaemon-OpenSSL/openssl-3.5.1.zip"
set "INSTALLER_FILE=%DOWNLOAD_DIR%\FireDaemon-OpenSSL-x64-3.5.1.exe"
set "ZIP_FILE=%DOWNLOAD_DIR%\openssl-3.5.1.zip"

:: SHA256 checksums for verification
set "INSTALLER_SHA256=04964BAB05C04930F6777CE071F2D3AAAD43162B5B25DF58D3130EFBECCAC7DB"
set "ZIP_SHA256=8C79BB13DE52EB90840664CC84E458CA983C961932E042157C5FBA8DFCC6C1C8"

echo Available OpenSSL downloads:
echo.
echo 1. OpenSSL %OPENSSL_VERSION% LTS x64 Installer (Recommended)
echo    - Easy installation with Windows installer
echo    - Automatically sets up paths and environment
echo    - File: FireDaemon-OpenSSL-x64-3.5.1.exe
echo    - Size: ~8MB
echo.
echo 2. OpenSSL %OPENSSL_VERSION% LTS ZIP Archive (Portable)
echo    - Portable installation
echo    - Includes x86, x64, and ARM64 binaries
echo    - File: openssl-3.5.1.zip
echo    - Size: ~12MB
echo.
echo 3. Download both versions
echo 4. Exit
echo.

:choice
set /p "choice=Please select an option (1-4): "

if "%choice%"=="1" goto download_installer
if "%choice%"=="2" goto download_zip
if "%choice%"=="3" goto download_both
if "%choice%"=="4" goto exit
echo Invalid choice. Please enter 1, 2, 3, or 4.
goto choice

:download_installer
echo.
echo Downloading OpenSSL %OPENSSL_VERSION% LTS x64 Installer...
echo From: %INSTALLER_URL%
echo To: %INSTALLER_FILE%
echo.

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%INSTALLER_URL%' -OutFile '%INSTALLER_FILE%' -UseBasicParsing; Write-Host 'Download completed successfully.' } catch { Write-Host 'Download failed: ' $_.Exception.Message; exit 1 }}"

if %errorlevel% neq 0 (
    echo ERROR: Download failed!
    pause
    goto exit
)

call :verify_checksum "%INSTALLER_FILE%" "%INSTALLER_SHA256%"
if %errorlevel% neq 0 goto exit

echo.
echo Download completed successfully!
echo File location: %INSTALLER_FILE%
echo.
set /p "install_now=Would you like to install OpenSSL now? (y/n): "
if /i "%install_now%"=="y" (
    echo Installing OpenSSL...
    "%INSTALLER_FILE%" /S
    echo Installation completed!
)
goto end

:download_zip
echo.
echo Downloading OpenSSL %OPENSSL_VERSION% LTS ZIP Archive...
echo From: %ZIP_URL%
echo To: %ZIP_FILE%
echo.

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing; Write-Host 'Download completed successfully.' } catch { Write-Host 'Download failed: ' $_.Exception.Message; exit 1 }}"

if %errorlevel% neq 0 (
    echo ERROR: Download failed!
    pause
    goto exit
)

call :verify_checksum "%ZIP_FILE%" "%ZIP_SHA256%"
if %errorlevel% neq 0 goto exit

echo.
echo Download completed successfully!
echo File location: %ZIP_FILE%
echo.
echo To use the ZIP version:
echo 1. Extract the ZIP file to your desired location (e.g., C:\OpenSSL)
echo 2. Add the bin directory to your system PATH
echo 3. Set OPENSSL_CONF environment variable to point to ssl\openssl.cnf
echo.
set /p "extract_now=Would you like to extract the ZIP file now? (y/n): "
if /i "%extract_now%"=="y" (
    echo Extracting ZIP file...
    powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%DOWNLOAD_DIR%\OpenSSL-Extracted' -Force"
    echo Extraction completed to: %DOWNLOAD_DIR%\OpenSSL-Extracted
)
goto end

:download_both
echo.
echo Downloading both OpenSSL versions...
echo.

echo [1/2] Downloading Installer...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%INSTALLER_URL%' -OutFile '%INSTALLER_FILE%' -UseBasicParsing; Write-Host 'Installer download completed.' } catch { Write-Host 'Installer download failed: ' $_.Exception.Message; exit 1 }}"

if %errorlevel% neq 0 (
    echo ERROR: Installer download failed!
    pause
    goto exit
)

echo [2/2] Downloading ZIP Archive...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing; Write-Host 'ZIP download completed.' } catch { Write-Host 'ZIP download failed: ' $_.Exception.Message; exit 1 }}"

if %errorlevel% neq 0 (
    echo ERROR: ZIP download failed!
    pause
    goto exit
)

echo.
echo Verifying checksums...
call :verify_checksum "%INSTALLER_FILE%" "%INSTALLER_SHA256%"
call :verify_checksum "%ZIP_FILE%" "%ZIP_SHA256%"

echo.
echo Both downloads completed successfully!
echo Installer: %INSTALLER_FILE%
echo ZIP: %ZIP_FILE%
goto end

:verify_checksum
echo Verifying checksum for %~nx1...
powershell -Command "& {$hash = Get-FileHash -Path '%~1' -Algorithm SHA256; if ($hash.Hash -eq '%~2') { Write-Host 'Checksum verification: PASSED' -ForegroundColor Green } else { Write-Host 'Checksum verification: FAILED' -ForegroundColor Red; Write-Host 'Expected: %~2'; Write-Host 'Actual: ' $hash.Hash; exit 1 }}"
if %errorlevel% neq 0 (
    echo ERROR: Checksum verification failed! File may be corrupted.
    pause
    exit /b 1
)
exit /b 0

:end
echo.
echo ==========================================
echo  OpenSSL Download Complete
echo ==========================================
echo.
echo OpenSSL Information:
echo - Version: %OPENSSL_VERSION% LTS (Long Term Support)
echo - Support until: April 8, 2030
echo - Source: FireDaemon (Official OpenSSL Binary Distribution)
echo - Compatible with: Windows 11, Windows 10, Windows Server 2016+
echo.
echo For more information, visit:
echo https://kb.firedaemon.com/support/solutions/articles/4000121705
echo.
echo Documentation and guides available at:
echo https://www.openssl.org/docs/
echo.
pause
goto exit

:exit
echo.
echo Exiting OpenSSL Download Script...
endlocal
exit /b 0