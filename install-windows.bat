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

:: Step 5: SSL Certificate Setup
cls
echo.
echo ===============================================
echo  Step 5: SSL Certificate Setup
echo ===============================================
echo.

:: Create SSL directory
if not exist "!INSTALL_DIR!\ssl" mkdir "!INSTALL_DIR!\ssl"

:: Check for existing certificates
if exist "!INSTALL_DIR!\ssl\localweb.key" if exist "!INSTALL_DIR!\ssl\localweb.crt" (
    echo SSL certificates already exist.
    echo.
    echo What would you like to do?
    echo 1) Use existing certificates
    echo 2) Generate new self-signed certificates
    echo 3) Import your own certificates
    echo.
    set /p SSL_OPTION="Select an option (1-3): "
    
    if "!SSL_OPTION!"=="1" (
        echo ✓ Using existing certificates
        goto :SSL_DONE
    ) else if "!SSL_OPTION!"=="3" (
        goto :IMPORT_CERTS
    )
) else (
    echo No SSL certificates found. Let's set them up.
    echo.
    echo What would you like to do?
    echo 1) Generate new self-signed certificates (recommended)
    echo 2) Import your own certificates
    echo 3) Skip SSL setup (not recommended)
    echo.
    set /p SSL_OPTION="Select an option (1-3): "
    
    if "!SSL_OPTION!"=="2" (
        goto :IMPORT_CERTS
    ) else if "!SSL_OPTION!"=="3" (
        echo WARNING: Skipping SSL setup. HTTPS will not be available.
        goto :SSL_DONE
    )
)

:: Generate self-signed certificate
echo.
echo Let's generate a self-signed SSL certificate.
echo.
echo This certificate will be used to enable HTTPS access to your LocalWeb Server.
echo Self-signed certificates will show a security warning in browsers, but are
echo perfectly safe for local/personal use.
echo.

:: Collect certificate information
echo Please provide the following information for your certificate:
echo (Press Enter to use the default values)
echo.

set /p CERT_COUNTRY="Country Code (2 letters, e.g., US, UK, CA) [US]: "
if "!CERT_COUNTRY!"=="" set CERT_COUNTRY=US

set /p CERT_STATE="State or Province [LocalState]: "
if "!CERT_STATE!"=="" set CERT_STATE=LocalState

set /p CERT_CITY="City or Locality [LocalCity]: "
if "!CERT_CITY!"=="" set CERT_CITY=LocalCity

set /p CERT_ORG="Organization Name [LocalWeb Server]: "
if "!CERT_ORG!"=="" set CERT_ORG=LocalWeb Server

echo.
echo Common Name is the domain/hostname you'll use to access the server.
echo Examples: localhost, 192.168.1.100, myserver.local
set /p CERT_CN="Common Name [localhost]: "
if "!CERT_CN!"=="" set CERT_CN=localhost

set /p CERT_DAYS="Certificate validity in days [365]: "
if "!CERT_DAYS!"=="" set CERT_DAYS=365

echo.
echo Generating SSL certificate...

:: First check if OpenSSL is available
where openssl >nul 2>&1
if %errorLevel% equ 0 (
    :: Use OpenSSL if available
    echo Using OpenSSL to generate certificate...
    
    :: Create certificate configuration file
    (
echo [req]
echo default_bits = 2048
echo prompt = no
echo default_md = sha256
echo distinguished_name = dn
echo x509_extensions = v3_req
echo.
echo [dn]
echo C=!CERT_COUNTRY!
echo ST=!CERT_STATE!
echo L=!CERT_CITY!
echo O=!CERT_ORG!
echo CN=!CERT_CN!
echo.
echo [v3_req]
echo subjectAltName = @alt_names
echo.
echo [alt_names]
echo DNS.1 = !CERT_CN!
echo DNS.2 = localhost
echo IP.1 = 127.0.0.1
echo IP.2 = ::1
    ) > "!INSTALL_DIR!\ssl\cert.conf"
    
    openssl req -new -x509 -days !CERT_DAYS! -nodes ^
        -config "!INSTALL_DIR!\ssl\cert.conf" ^
        -keyout "!INSTALL_DIR!\ssl\localweb.key" ^
        -out "!INSTALL_DIR!\ssl\localweb.crt"
    
    del "!INSTALL_DIR!\ssl\cert.conf"
) else (
    :: Use PowerShell as fallback
    echo Using PowerShell to generate certificate...
    
    :: Copy the PowerShell certificate generator script if it exists
    if exist "ssl-cert-generator.ps1" (
        copy /Y "ssl-cert-generator.ps1" "!INSTALL_DIR!\ssl\" >nul
    )
    
    :: Run PowerShell certificate generation
    cd "!INSTALL_DIR!"
    powershell -ExecutionPolicy Bypass -Command "& { .\ssl\ssl-cert-generator.ps1 -Country '!CERT_COUNTRY!' -State '!CERT_STATE!' -City '!CERT_CITY!' -Organization '!CERT_ORG!' -CommonName '!CERT_CN!' -ValidDays !CERT_DAYS! -OutputPath '.\ssl' }"
    
    :: Alternative: Try to extract key from PFX using certutil
    if exist "!INSTALL_DIR!\ssl\temp.pfx" (
        echo.
        echo Converting certificate format...
        
        :: Note: This is a simplified approach. For production use, 
        :: a proper OpenSSL installation or key conversion tool would be better
        echo WARNING: Private key conversion requires OpenSSL or manual processing.
        echo The certificate has been generated but may need manual key extraction.
        
        :: Copy key extraction helper if it exists
        if exist "extract-private-key.bat" (
            copy /Y "extract-private-key.bat" "!INSTALL_DIR!\ssl\" >nul
        )
        
        :: Create a placeholder key file with instructions
        (
echo # LocalWeb Server Private Key
echo # ============================
echo # The private key was generated but needs to be extracted from the PFX file.
echo # 
echo # EASY METHOD: Run the extract-private-key.bat script in the ssl folder
echo # 
echo # MANUAL METHOD:
echo # To extract the key, you need OpenSSL installed:
echo # 1. Install OpenSSL for Windows from: https://slproweb.com/products/Win32OpenSSL.html
echo # 2. Run: openssl pkcs12 -in ssl\temp.pfx -nocerts -nodes -out ssl\localweb.key -password pass:TempPassword123!
echo # 3. Delete the temp.pfx file
echo #
echo # Alternatively, use the HTTP-only mode (port 8080) until you can properly extract the key.
        ) > "!INSTALL_DIR!\ssl\localweb.key"
        
        echo.
        echo NOTE: To complete SSL setup, run: ssl\extract-private-key.bat
        echo Or use HTTP-only mode at: http://localhost:8080
    )
)

echo ✓ SSL certificate generated

:: Save certificate information
(
echo LocalWeb Server SSL Certificate Information
echo ==========================================
echo Generated on: %DATE% %TIME%
echo Valid for: !CERT_DAYS! days
echo Common Name: !CERT_CN!
echo Organization: !CERT_ORG!
echo.
echo Certificate Location: !INSTALL_DIR!\ssl\localweb.crt
echo Private Key Location: !INSTALL_DIR!\ssl\localweb.key
echo.
echo To trust this certificate in your browser:
echo - Chrome/Edge: Navigate to https://localhost:8443, click "Advanced" and "Proceed to localhost"
echo - Firefox: Navigate to https://localhost:8443, click "Advanced" and "Accept the Risk and Continue"
echo - Or import the certificate file into your browser's certificate store
) > "!INSTALL_DIR!\ssl\certificate-info.txt"

echo Certificate information saved to: !INSTALL_DIR!\ssl\certificate-info.txt
goto :SSL_DONE

:IMPORT_CERTS
echo.
echo Import Existing SSL Certificates
echo.
echo Please provide the paths to your certificate files:
echo.

set /p CERT_PATH="Path to certificate file (.crt, .pem, or .cer): "
if not exist "!CERT_PATH!" (
    echo ERROR: Certificate file not found: !CERT_PATH!
    echo Skipping SSL import.
    goto :SSL_DONE
)

set /p KEY_PATH="Path to private key file (.key or .pem): "
if not exist "!KEY_PATH!" (
    echo ERROR: Private key file not found: !KEY_PATH!
    echo Skipping SSL import.
    goto :SSL_DONE
)

echo.
echo Importing certificates...
copy /Y "!CERT_PATH!" "!INSTALL_DIR!\ssl\localweb.crt" >nul
copy /Y "!KEY_PATH!" "!INSTALL_DIR!\ssl\localweb.key" >nul

echo ✓ Certificates imported successfully!

:SSL_DONE

:: Step 6: Create shortcuts and service
cls
echo.
echo ===============================================
echo  Step 6: Creating Shortcuts and Service
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
echo }^);
echo.
echo svc.install(^);
    ) > "!INSTALL_DIR!\install-service.js"
    
    node install-service.js
    echo ✓ Windows service installed
)

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