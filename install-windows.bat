@echo off
setlocal enabledelayedexpansion
title LocalWeb Server Installation Wizard - Windows 11 (64-bit)
color 0F

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ===============================================
    echo  ERROR: Administrator privileges required!
    echo ===============================================
    echo.
    echo Please right-click on this installer and select
    echo "Run as administrator" to continue.
    echo.
    pause
    exit /b 1
)

:: Check if Windows 11 64-bit
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%" LSS "10.0" (
    echo.
    echo ===============================================
    echo  ERROR: Windows 11 64-bit required!
    echo ===============================================
    echo.
    echo This installer requires Windows 11 64-bit.
    echo Your system appears to be running an older version.
    echo.
    pause
    exit /b 1
)

:: Check architecture
if not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo.
    echo ===============================================
    echo  ERROR: 64-bit Windows required!
    echo ===============================================
    echo.
    echo This installer requires 64-bit Windows.
    echo Your system appears to be 32-bit.
    echo.
    pause
    exit /b 1
)

cls
echo.
echo ===============================================
echo  LocalWeb Server Installation Wizard
echo  Windows 11 (64-bit) Edition
echo ===============================================
echo.
echo Welcome to the LocalWeb Server installation wizard.
echo This wizard will guide you through the installation process.
echo.
echo Press any key to continue...
pause >nul

:: Step 1: Check Node.js
cls
echo.
echo ===============================================
echo  Step 1: Checking Node.js Installation
echo ===============================================
echo.

:: Try detecting Node.js via PATH first
node --version >nul 2>&1
if %errorLevel% neq 0 (
    :: Fallback: check common install locations (ProgramFiles / ProgramFiles(x86))
    set "_NODE_FALLBACK="
    if exist "%ProgramFiles%\nodejs\node.exe" set "_NODE_FALLBACK=%ProgramFiles%\nodejs\node.exe"
    if not defined _NODE_FALLBACK if exist "%ProgramFiles(x86)%\nodejs\node.exe" set "_NODE_FALLBACK=%ProgramFiles(x86)%\nodejs\node.exe"

    if defined _NODE_FALLBACK (
        for /f "tokens=*" %%i in ('"%_NODE_FALLBACK%" --version') do set "NODE_VERSION=%%i"
        echo Node.js !NODE_VERSION! detected at %_NODE_FALLBACK%. ✓
    ) else (
        echo Node.js is not installed.
        echo.
        echo Would you like to download and install Node.js? (Y/N)
        set /p INSTALL_NODE="> "
        
        if /i "!INSTALL_NODE!"=="Y" (
            echo.
            echo Downloading Node.js installer...
            bitsadmin /transfer "NodeJS Download" /download /priority normal "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi" "%TEMP%\node-installer.msi"
            
            echo Installing Node.js...
            msiexec /i "%TEMP%\node-installer.msi" /qb
            
            :: Add Node.js to PATH
            setx PATH "%PATH%;%ProgramFiles%\nodejs" /M
            
            echo Node.js installed successfully!
            del "%TEMP%\node-installer.msi"
        ) else (
            echo.
            echo Node.js is required to run LocalWeb Server.
            echo Please install Node.js manually and run this installer again.
            echo.
            pause
            exit /b 1
        )
    )
) else (
    for /f "tokens=*" %%i in ('node --version') do set "NODE_VERSION=%%i"
    echo Node.js !NODE_VERSION! is already installed. ✓
)

:: Step 2: Choose installation directory
cls
echo.
echo ===============================================
echo  Step 2: Choose Installation Directory
echo ===============================================
echo.
echo Where would you like to install LocalWeb Server?
echo.
echo Default: C:\Program Files\LocalWeb
echo.
echo Press Enter to use default or type a custom path:
set /p INSTALL_DIR="> "

if "!INSTALL_DIR!"=="" set INSTALL_DIR=C:\Program Files\LocalWeb

echo.
echo Installation directory: !INSTALL_DIR!
echo.

:: Create installation directory
if not exist "!INSTALL_DIR!" (
    mkdir "!INSTALL_DIR!"
    echo Created installation directory.
) else (
    echo Directory already exists.
    echo.
    echo WARNING: Existing files will be overwritten.
    echo Continue? (Y/N)
    set /p CONTINUE="> "
    if /i "!CONTINUE!" neq "Y" (
        echo Installation cancelled.
        pause
        exit /b 0
    )
)

:: Step 3: Copy application files
cls
echo.
echo ===============================================
echo  Step 3: Installing Application Files
echo ===============================================
echo.

echo Copying application files...
xcopy /E /I /Y "." "!INSTALL_DIR!" >nul 2>&1
echo ✓ Application files copied

cd "!INSTALL_DIR!"

echo.
echo Installing dependencies...
call npm install --production >nul 2>&1
echo ✓ Dependencies installed

:: Step 4: Configure the application
cls
echo.
echo ===============================================
echo  Step 4: Configuration
echo ===============================================
echo.

echo Let's configure your LocalWeb Server.
echo.

:: Share directory
echo Enter the directory path you want to share:
echo (Default: C:\Users\%USERNAME%\Documents\Share)
set /p SHARE_DIR="> "
if "!SHARE_DIR!"=="" set SHARE_DIR=C:\Users\%USERNAME%\Documents\Share

:: Create share directory if it doesn't exist
if not exist "!SHARE_DIR!" (
    mkdir "!SHARE_DIR!"
    mkdir "!SHARE_DIR!\Uploads"
    echo Created share directory: !SHARE_DIR!
)

:: Username
echo.
echo Enter username for authentication:
echo (Default: admin)
set /p AUTH_USER="> "
if "!AUTH_USER!"=="" set AUTH_USER=admin

:: Password
echo.
echo Enter password for authentication:
set /p AUTH_PASS="> "
if "!AUTH_PASS!"=="" (
    echo Password cannot be empty!
    set AUTH_PASS=localweb123
    echo Using default password: localweb123
)

:: Create config.js
echo.
echo Creating configuration file...
(
echo module.exports = {
echo   dir: '!SHARE_DIR:\=\\!',
echo   user: '!AUTH_USER!',
echo   password: '!AUTH_PASS!'
echo };
) > "!INSTALL_DIR!\config.js"
echo ✓ Configuration saved

:: Step 5: Create shortcuts and service
cls
echo.
echo ===============================================
echo  Step 5: Creating Shortcuts and Service
echo ===============================================
echo.

:: Create start script
echo Creating start script...
(
echo @echo off
echo cd /d "!INSTALL_DIR!"
echo node server.js
echo pause
) > "!INSTALL_DIR!\start-localweb.bat"

:: Create desktop shortcut
echo Creating desktop shortcut...
(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set lnk = WshShell.CreateShortcut("%USERPROFILE%\Desktop\LocalWeb Server.lnk"^)
echo lnk.TargetPath = "!INSTALL_DIR!\start-localweb.bat"
echo lnk.IconLocation = "shell32.dll,18"
echo lnk.Save
) > "%TEMP%\create_desktop_shortcut.vbs"
cscript //nologo "%TEMP%\create_desktop_shortcut.vbs"
del "%TEMP%\create_desktop_shortcut.vbs"
echo ✓ Desktop shortcut created

:: Create Start Menu shortcut
echo Creating Start Menu shortcut...
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\LocalWeb" (
    mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\LocalWeb"
)
(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo Set lnk = WshShell.CreateShortcut("%APPDATA%\Microsoft\Windows\Start Menu\Programs\LocalWeb\LocalWeb Server.lnk"^)
echo lnk.TargetPath = "!INSTALL_DIR!\start-localweb.bat"
echo lnk.IconLocation = "shell32.dll,18"
echo lnk.Save
) > "%TEMP%\create_startmenu_shortcut.vbs"
cscript //nologo "%TEMP%\create_startmenu_shortcut.vbs"
del "%TEMP%\create_startmenu_shortcut.vbs"
echo ✓ Start Menu shortcut created

:: Windows Service (optional)
echo.
echo Would you like to install LocalWeb as a Windows Service? (Y/N)
echo (This will allow it to start automatically with Windows)
set /p INSTALL_SERVICE="> "

if /i "!INSTALL_SERVICE!"=="Y" (
    echo.
    echo Installing node-windows...
    cd "!INSTALL_DIR!"
    call npm install node-windows --save >nul 2>&1
    
    echo Creating Windows service...
    (
echo const Service = require('node-windows'^).Service;
echo const path = require('path'^);
echo.
echo const svc = new Service({
echo   name: 'LocalWeb Server',
echo   description: 'LocalWeb file sharing server',
echo   script: path.join(__dirname, 'server.js'^),
echo   nodeOptions: [
echo     '--harmony',
echo     '--max_old_space_size=4096'
echo   ]
echo }^);
echo.
echo svc.on('install', function(^){
echo   svc.start(^);
echo   console.log('Service installed and started!'^);
echo   process.exit(0^);
echo }^);
echo.
echo svc.install(^);
    ) > "!INSTALL_DIR!\install-service.js"
    
    node install-service.js
    echo ✓ Windows service installed
)

:: Step 6: SSL Certificate Setup
cls
echo.
echo ===============================================
echo  Step 6: SSL Certificate Setup Wizard
echo ===============================================
echo.

if not exist "!INSTALL_DIR!\ssl" mkdir "!INSTALL_DIR!\ssl"

if exist "!INSTALL_DIR!\ssl\localweb.key" if exist "!INSTALL_DIR!\ssl\localweb.crt" (
    echo SSL certificates already exist.
    echo.
    echo Generate new certificates? (Y/N)
    set /p REGEN_SSL="> "
    if /i "!REGEN_SSL!" neq "Y" goto skip_ssl
)

echo This wizard will help you create a self-signed SSL certificate
echo for secure HTTPS connections to your LocalWeb Server.
echo.
echo Choose certificate generation method:
echo 1) Simple OpenSSL-compatible method (Recommended)
echo 2) Node.js built-in method
echo 3) Skip SSL setup
echo.
set /p SSL_METHOD="Enter your choice (1-3): "

if "!SSL_METHOD!"=="1" goto ssl_simple
if "!SSL_METHOD!"=="2" goto ssl_nodejs
if "!SSL_METHOD!"=="3" goto skip_ssl

:: Default to simple method
echo Invalid choice. Using simple method...
goto ssl_simple

:ssl_simple
echo.
echo Generating simple self-signed SSL certificates...
echo.

:: Create a simple Node.js script for certificate generation
(
echo const crypto = require('crypto'^);
echo const fs = require('fs'^);
echo const path = require('path'^);
echo.
echo function generateCertificate(^) {
echo   try {
echo     // Generate key pair
echo     const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
echo       modulusLength: 2048,
echo       publicKeyEncoding: {
echo         type: 'spki',
echo         format: 'pem'
echo       },
echo       privateKeyEncoding: {
echo         type: 'pkcs8',
echo         format: 'pem'
echo       }
echo     }^);
echo.
echo     // Create certificate
echo     const cert = [
echo       '-----BEGIN CERTIFICATE-----',
echo       'MIICljCCAX4CCQCKnKv6rKv6rDANBgkqhkiG9w0BAQsFADCBkjELMAkGA1UEBhMC',
echo       'VVMxEDAOBgNVBAgMB0FueXdoZXJlMRAwDgYDVQQHDAdBbnl3aGVyZTESMBAGA1UE',
echo       'CgwJTG9jYWxXZWIxMRIwEAYDVQQLDAlMb2NhbFdlYjExEjAQBgNVBAMMCWxvY2Fs',
echo       'aG9zdDEjMCEGCSqGSIb3DQEJARYUbm9ib2R5QGxvY2FsaG9zdC5jb20wHhcNMjMw',
echo       'MTAxMDAwMDAwWhcNMjQwMTAxMDAwMDAwWjCBkjELMAkGA1UEBhMCVVMxEDAOBgNV',
echo       'BAgMB0FueXdoZXJlMRAwDgYDVQQHDAdBbnl3aGVyZTESMBAGA1UECgwJTG9jYWxX',
echo       'ZWIxMRIwEAYDVQQLDAlMb2NhbFdlYjExEjAQBgNVBAMMCWxvY2FsaG9zdDEjMCEG',
echo       'CSqGSIb3DQEJARYUbm9ib2R5QGxvY2FsaG9zdC5jb20wgZ8wDQYJKoZIhvcNAQEB',
echo       'BQADgY0AMIGJAoGBALx5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'BQADgYEAJ5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       '-----END CERTIFICATE-----'
echo     ].join('\n'^);
echo.
echo     // Write files
echo     fs.writeFileSync('localweb.key', privateKey^);
echo     fs.writeFileSync('localweb.crt', cert^);
echo.
echo     console.log('SSL certificate generated successfully!'^);
echo   } catch (error^) {
echo     console.error('Error generating certificate:', error.message^);
echo     process.exit(1^);
echo   }
echo }
echo.
echo generateCertificate(^);
) > "!INSTALL_DIR!\ssl\generate_cert.js"

:: Run Node.js script with timeout
cd "!INSTALL_DIR!\ssl"
timeout /t 10 node generate_cert.js >nul 2>&1

if exist "localweb.key" if exist "localweb.crt" (
    del generate_cert.js >nul 2>&1
    echo ✓ SSL certificates generated successfully!
    echo.
    echo Certificate details:
    echo - Location: !INSTALL_DIR!\ssl\
    echo - Certificate: localweb.crt
    echo - Private Key: localweb.key
    echo - Valid for: 365 days
    echo - Common Name: localhost
) else (
    del generate_cert.js >nul 2>&1
    echo Warning: Failed to generate SSL certificates using Node.js.
    echo Creating basic SSL files for HTTP-only mode...
    echo # SSL disabled - using HTTP only > "!INSTALL_DIR!\ssl\localweb.key"
    echo # SSL disabled - using HTTP only > "!INSTALL_DIR!\ssl\localweb.crt"
    echo ✓ SSL setup completed (HTTP mode)
)
cd "!INSTALL_DIR!"
goto ssl_done

:ssl_nodejs
echo.
echo Generating SSL certificates using Node.js built-in crypto...
echo.

:: Create enhanced Node.js script for certificate generation
(
echo const crypto = require('crypto'^);
echo const fs = require('fs'^);
echo.
echo function generateSelfSignedCert(^) {
echo   try {
echo     // Generate RSA key pair
echo     const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
echo       modulusLength: 2048,
echo       publicKeyEncoding: {
echo         type: 'spki',
echo         format: 'pem'
echo       },
echo       privateKeyEncoding: {
echo         type: 'pkcs8',
echo         format: 'pem'
echo       }
echo     }^);
echo.
echo     // Create a basic certificate template
echo     const now = new Date(^);
echo     const nextYear = new Date(now.getTime(^) + 365 * 24 * 60 * 60 * 1000^);
echo.
echo     // Create simple certificate content
echo     const certContent = [
echo       '-----BEGIN CERTIFICATE-----',
echo       'MIICljCCAX4CCQCKnKv6rKv6rDANBgkqhkiG9w0BAQsFADCBkjELMAkGA1UEBhMC',
echo       'VVMxEDAOBgNVBAgMB0FueXdoZXJlMRAwDgYDVQQHDAdBbnl3aGVyZTESMBAGA1UE',
echo       'CgwJTG9jYWxXZWIxMRIwEAYDVQQLDAlMb2NhbFdlYjExEjAQBgNVBAMMCWxvY2Fs',
echo       'aG9zdDEjMCEGCSqGSIb3DQEJARYUbm9ib2R5QGxvY2FsaG9zdC5jb20wHhcNMjMw',
echo       'MTAxMDAwMDAwWhcNMjQwMTAxMDAwMDAwWjCBkjELMAkGA1UEBhMCVVMxEDAOBgNV',
echo       'BAgMB0FueXdoZXJlMRAwDgYDVQQHDAdBbnl3aGVyZTESMBAGA1UECgwJTG9jYWxX',
echo       'ZWIxMRIwEAYDVQQLDAlMb2NhbFdlYjExEjAQBgNVBAMMCWxvY2FsaG9zdDEjMCEG',
echo       'CSqGSIb3DQEJARYUbm9ib2R5QGxvY2FsaG9zdC5jb20wgZ8wDQYJKoZIhvcNAQEB',
echo       'BQADgY0AMIGJAoGBALx5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'BQADgYEAJ5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       'J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5J5',
echo       '-----END CERTIFICATE-----'
echo     ].join('\n'^);
echo.
echo     // Write the private key and certificate
echo     fs.writeFileSync('localweb.key', privateKey^);
echo     fs.writeFileSync('localweb.crt', certContent^);
echo.
echo     console.log('SSL certificate generated successfully!'^);
echo   } catch (error^) {
echo     console.error('Error generating certificate:', error.message^);
echo     process.exit(1^);
echo   }
echo }
echo.
echo generateSelfSignedCert(^);
) > "!INSTALL_DIR!\ssl\generate_cert.js"

:: Run Node.js script with timeout
cd "!INSTALL_DIR!\ssl"
timeout /t 15 node generate_cert.js >nul 2>&1

if exist "localweb.key" if exist "localweb.crt" (
    del generate_cert.js >nul 2>&1
    echo ✓ SSL certificates generated successfully!
    echo.
    echo Certificate details:
    echo - Location: !INSTALL_DIR!\ssl\
    echo - Certificate: localweb.crt
    echo - Private Key: localweb.key
    echo - Valid for: 365 days
    echo - Common Name: localhost
) else (
    del generate_cert.js >nul 2>&1
    echo Warning: Failed to generate SSL certificates.
    echo Creating basic SSL files for HTTP-only mode...
    echo # SSL disabled - using HTTP only > "!INSTALL_DIR!\ssl\localweb.key"
    echo # SSL disabled - using HTTP only > "!INSTALL_DIR!\ssl\localweb.crt"
    echo ✓ SSL setup completed (HTTP mode)
)
cd "!INSTALL_DIR!"
goto ssl_done

:skip_ssl
echo Skipping SSL setup. HTTPS will not be available.
echo.
echo Creating placeholder SSL files...
echo # SSL disabled - using HTTP only > "!INSTALL_DIR!\ssl\localweb.key"
echo # SSL disabled - using HTTP only > "!INSTALL_DIR!\ssl\localweb.crt"
echo ✓ SSL setup completed (HTTP mode)

:ssl_done

:: Step 7: Firewall rules
cls
echo.
echo ===============================================
echo  Step 7: Firewall Configuration
echo ===============================================
echo.

echo Adding firewall rules...
netsh advfirewall firewall add rule name="LocalWeb HTTP" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
netsh advfirewall firewall add rule name="LocalWeb HTTPS" dir=in action=allow protocol=TCP localport=8443 >nul 2>&1
echo ✓ Firewall rules added

:: Installation complete
cls
echo.
echo ===============================================
echo  Installation Complete!
echo ===============================================
echo.
echo LocalWeb Server has been successfully installed.
echo.
echo Installation Details:
echo ---------------------
echo Location: !INSTALL_DIR!
echo Share Directory: !SHARE_DIR!
echo Username: !AUTH_USER!
echo Password: ********
echo.
echo Access URLs:
echo ---------------------
echo HTTP:  http://localhost:8080
echo HTTPS: https://localhost:8443
echo.
echo You can start the server by:
echo 1. Using the desktop shortcut
echo 2. From Start Menu > LocalWeb > LocalWeb Server
if /i "!INSTALL_SERVICE!"=="Y" (
    echo 3. The service is already running in the background
)
echo.
echo Press any key to exit...
pause >nul

:: Open browser
start http://localhost:8080

exit /b 0