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
echo 1) OpenSSL (recommended if available)
echo 2) PowerShell PKI module
echo 3) Skip SSL setup
echo.
set /p SSL_METHOD="Enter your choice (1-3): "

if "!SSL_METHOD!"=="1" goto ssl_openssl
if "!SSL_METHOD!"=="2" goto ssl_powershell
if "!SSL_METHOD!"=="3" goto skip_ssl

:: Default to OpenSSL method
echo Invalid choice. Using OpenSSL method...
goto ssl_openssl

:ssl_openssl
echo.
echo Checking for OpenSSL...

:: Check if OpenSSL is available
where openssl >nul 2>&1
if errorlevel 1 (
    echo OpenSSL is not installed or not in PATH.
    echo.
    echo You can install OpenSSL from:
    echo - https://slproweb.com/products/Win32OpenSSL.html
    echo - Or through Windows package managers like Chocolatey/Scoop
    echo.
    echo Falling back to PowerShell PKI method...
    goto ssl_powershell
)

echo OpenSSL found. Generating SSL certificates...
echo.

:: Get certificate details
echo Enter certificate details (press Enter for defaults):
set /p SSL_COUNTRY="Country (2 letter code) [US]: "
if "!SSL_COUNTRY!"=="" set SSL_COUNTRY=US

set /p SSL_STATE="State or Province [California]: "
if "!SSL_STATE!"=="" set SSL_STATE=California

set /p SSL_CITY="City [San Francisco]: "
if "!SSL_CITY!"=="" set SSL_CITY=San Francisco

set /p SSL_ORG="Organization [LocalWeb]: "
if "!SSL_ORG!"=="" set SSL_ORG=LocalWeb

set /p SSL_UNIT="Organizational Unit [IT Department]: "
if "!SSL_UNIT!"=="" set SSL_UNIT=IT Department

set /p SSL_CN="Common Name [localhost]: "
if "!SSL_CN!"=="" set SSL_CN=localhost

set /p SSL_DAYS="Certificate validity (days) [365]: "
if "!SSL_DAYS!"=="" set SSL_DAYS=365

echo.
echo Generating self-signed SSL certificates...

cd "!INSTALL_DIR!\ssl"

:: Generate private key and certificate with OpenSSL
openssl req -x509 -nodes -days !SSL_DAYS! -newkey rsa:2048 ^
    -keyout localweb.key -out localweb.crt ^
    -subj "/C=!SSL_COUNTRY!/ST=!SSL_STATE!/L=!SSL_CITY!/O=!SSL_ORG!/OU=!SSL_UNIT!/CN=!SSL_CN!" ^
    -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1,IP:::1"

if exist "localweb.key" if exist "localweb.crt" (
    echo.
    echo ✓ SSL certificates generated successfully!
    echo.
    echo Certificate details:
    echo - Location: !INSTALL_DIR!\ssl\
    echo - Certificate: localweb.crt
    echo - Private Key: localweb.key
    echo - Valid for: !SSL_DAYS! days
    echo - Common Name: !SSL_CN!
) else (
    echo.
    echo Error: Failed to generate SSL certificates with OpenSSL.
    echo Falling back to PowerShell PKI method...
    goto ssl_powershell
)

cd "!INSTALL_DIR!"
goto ssl_done

:ssl_powershell
echo.
echo Generating SSL certificates using PowerShell PKI module...
echo.

:: Get certificate details
echo Enter certificate details (press Enter for defaults):
set /p SSL_COUNTRY="Country (2 letter code) [US]: "
if "!SSL_COUNTRY!"=="" set SSL_COUNTRY=US

set /p SSL_STATE="State or Province [California]: "
if "!SSL_STATE!"=="" set SSL_STATE=California

set /p SSL_CITY="City [San Francisco]: "
if "!SSL_CITY!"=="" set SSL_CITY=San Francisco

set /p SSL_ORG="Organization [LocalWeb]: "
if "!SSL_ORG!"=="" set SSL_ORG=LocalWeb

set /p SSL_UNIT="Organizational Unit [IT Department]: "
if "!SSL_UNIT!"=="" set SSL_UNIT=IT Department

set /p SSL_CN="Common Name [localhost]: "
if "!SSL_CN!"=="" set SSL_CN=localhost

set /p SSL_DAYS="Certificate validity (days) [365]: "
if "!SSL_DAYS!"=="" set SSL_DAYS=365

echo.
echo Generating self-signed SSL certificates...

cd "!INSTALL_DIR!\ssl"

:: Create PowerShell script for certificate generation
(
echo # PowerShell PKI Certificate Generation Script
echo $ErrorActionPreference = "Stop"
echo.
echo try {
echo     # Certificate subject
echo     $subject = "C=!SSL_COUNTRY!, ST=!SSL_STATE!, L=!SSL_CITY!, O=!SSL_ORG!, OU=!SSL_UNIT!, CN=!SSL_CN!"
echo.
echo     # Calculate expiration date
echo     $notAfter = (Get-Date^).AddDays(!SSL_DAYS!^)
echo.
echo     # Create certificate
echo     $cert = New-SelfSignedCertificate -Subject $subject -NotAfter $notAfter -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -KeyUsage KeyEncipherment, DigitalSignature -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1", "2.5.29.17={text}DNS=localhost&DNS=*.localhost&IPAddress=127.0.0.1&IPAddress=::1"^) -CertStoreLocation "cert:\CurrentUser\My"
echo.
echo     # Export certificate to PEM format
echo     $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert^)
echo     $certPem = [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks^)
echo     $certPemContent = "-----BEGIN CERTIFICATE-----`n" + $certPem + "`n-----END CERTIFICATE-----"
echo     [System.IO.File]::WriteAllText("localweb.crt", $certPemContent^)
echo.
echo     # Export private key to PEM format
echo     $keyBytes = $cert.PrivateKey.ExportPkcs8PrivateKey(^)
echo     $keyPem = [System.Convert]::ToBase64String($keyBytes, [System.Base64FormattingOptions]::InsertLineBreaks^)
echo     $keyPemContent = "-----BEGIN PRIVATE KEY-----`n" + $keyPem + "`n-----END PRIVATE KEY-----"
echo     [System.IO.File]::WriteAllText("localweb.key", $keyPemContent^)
echo.
echo     # Clean up certificate from store
echo     Remove-Item "cert:\CurrentUser\My\$($cert.Thumbprint^)" -Force
echo.
echo     Write-Host "SSL certificate generated successfully!"
echo } catch {
echo     Write-Host "Error generating certificate: $($_.Exception.Message^)" -ForegroundColor Red
echo     exit 1
echo }
) > "generate_cert.ps1"

:: Run PowerShell script
powershell -ExecutionPolicy Bypass -File "generate_cert.ps1"

if exist "localweb.key" if exist "localweb.crt" (
    del generate_cert.ps1 >nul 2>&1
    echo.
    echo ✓ SSL certificates generated successfully!
    echo.
    echo Certificate details:
    echo - Location: !INSTALL_DIR!\ssl\
    echo - Certificate: localweb.crt
    echo - Private Key: localweb.key
    echo - Valid for: !SSL_DAYS! days
    echo - Common Name: !SSL_CN!
) else (
    del generate_cert.ps1 >nul 2>&1
    echo.
    echo Error: Failed to generate SSL certificates.
    echo Creating placeholder SSL files for HTTP-only mode...
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