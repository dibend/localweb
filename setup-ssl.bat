@echo off
setlocal enabledelayedexpansion
title LocalWeb Server SSL Certificate Setup - Windows Edition
color 0F

REM Standalone SSL Certificate Setup Script
REM For LocalWeb Server - Windows Edition
REM Version: 2.0 - Full Featured

cls
echo.
echo ===============================================
echo  LocalWeb Server SSL Certificate Setup
echo  Full-Featured Certificate Generation
echo ===============================================
echo.
echo This script will create a comprehensive SSL certificate setup
echo for your LocalWeb Server with the following features:
echo.
echo • Self-signed certificates with proper Subject Alternative Names
echo • Auto-detection of local IP addresses and hostnames
echo • Certificate validation and verification
echo • Multiple certificate formats (PEM, P12/PFX)
echo • Certificate management utilities
echo • Windows native compatibility
echo.
pause

REM Determine working directory
:determine_working_dir
set "WORK_DIR="

REM Check if we're in a LocalWeb installation directory
if exist "server.js" if exist "package.json" (
    set "WORK_DIR=%CD%"
    echo Detected LocalWeb installation in current directory
    goto :ssl_dir_setup
)

REM Look for common installation locations
set "POSSIBLE_DIRS=C:\Program Files\LocalWeb;C:\LocalWeb;%USERPROFILE%\LocalWeb;%USERPROFILE%\Documents\LocalWeb"

for %%d in (!POSSIBLE_DIRS!) do (
    if exist "%%d\server.js" (
        set "WORK_DIR=%%d"
        echo Found LocalWeb installation at: !WORK_DIR!
        goto :ssl_dir_setup
    )
)

REM If not found, ask user
echo LocalWeb installation not found. Please specify the directory:
set /p WORK_DIR="Enter LocalWeb directory path: "

if not exist "!WORK_DIR!" (
    echo Directory doesn't exist. Creating: !WORK_DIR!
    mkdir "!WORK_DIR!" 2>nul
)

:ssl_dir_setup
REM Create ssl directory
set "SSL_DIR=!WORK_DIR!\ssl"
if not exist "!SSL_DIR!" mkdir "!SSL_DIR!"

echo.
echo Working directory: !WORK_DIR!
echo SSL directory: !SSL_DIR!
echo.

REM Check for existing certificates
:check_existing
if exist "!SSL_DIR!\localweb.key" if exist "!SSL_DIR!\localweb.crt" (
    echo SSL certificates already exist.
    echo.
    echo Certificate Information:
    
    REM Display certificate info using OpenSSL if available
    where openssl >nul 2>&1
    if not errorlevel 1 (
        cd "!SSL_DIR!"
        echo Subject:
        openssl x509 -noout -subject -in localweb.crt 2>nul
        echo Issuer:
        openssl x509 -noout -issuer -in localweb.crt 2>nul
        echo Valid until:
        openssl x509 -noout -enddate -in localweb.crt 2>nul
        echo SANs:
        openssl x509 -noout -ext subjectAltName -in localweb.crt 2>nul
        cd "!WORK_DIR!"
    )
    
    echo.
    set /p REGEN="Generate new certificates? (y/N): "
    if /i "!REGEN!" neq "y" (
        echo Keeping existing certificates.
        goto :create_utilities
    )
)

REM Choose SSL method
:choose_method
cls
echo.
echo Choose certificate generation method:
echo 1) OpenSSL (recommended - full featured)
echo 2) PowerShell PKI (enhanced Windows native)
echo 3) Exit
echo.
set /p SSL_METHOD="Enter your choice (1-3): "

if "!SSL_METHOD!"=="1" goto :openssl_enhanced
if "!SSL_METHOD!"=="2" goto :powershell_enhanced
if "!SSL_METHOD!"=="3" goto :exit
echo Invalid choice. Using OpenSSL method...
goto :openssl_enhanced

:openssl_enhanced
echo.
echo Checking for OpenSSL...

REM Check if OpenSSL is available
where openssl >nul 2>&1
if errorlevel 1 (
    echo OpenSSL is not installed or not in PATH.
    echo.
    echo Attempting to install OpenSSL using winget...
    winget install --id ShiningLight.OpenSSL --silent --accept-package-agreements 2>nul
    
    REM Check again after installation attempt
    where openssl >nul 2>&1
    if errorlevel 1 (
        echo OpenSSL installation failed.
        echo.
        echo You can install OpenSSL from:
        echo - https://slproweb.com/products/Win32OpenSSL.html
        echo - Or use: winget install ShiningLight.OpenSSL
        echo.
        echo Falling back to PowerShell PKI method...
        goto :powershell_enhanced
    ) else (
        echo OpenSSL installed successfully!
    )
)

echo OpenSSL found. Generating comprehensive SSL certificates...
echo.

REM Auto-detect local information
for /f "tokens=*" %%i in ('hostname') do set "DETECTED_HOSTNAME=%%i"
for /f "tokens=*" %%i in ('echo %COMPUTERNAME%') do set "DETECTED_COMPUTERNAME=%%i"

REM Get local IP addresses
echo Auto-detecting local IP addresses...
set "LOCAL_IPS="
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    set "IP=%%i"
    set "IP=!IP: =!"
    if not "!IP!"=="127.0.0.1" (
        set "LOCAL_IPS=!LOCAL_IPS!!IP! "
    )
)

echo Detected hostname: !DETECTED_HOSTNAME!
echo Detected computer name: !DETECTED_COMPUTERNAME!
echo Detected IP addresses: !LOCAL_IPS!

REM Get certificate details with smart defaults
echo.
echo Enter certificate details (press Enter for detected/default values):
set /p SSL_COUNTRY="Country (2 letter code) [US]: "
if "!SSL_COUNTRY!"=="" set SSL_COUNTRY=US

set /p SSL_STATE="State or Province [Windows]: "
if "!SSL_STATE!"=="" set SSL_STATE=Windows

set /p SSL_CITY="City [LocalCity]: "
if "!SSL_CITY!"=="" set SSL_CITY=LocalCity

set /p SSL_ORG="Organization [LocalWeb Server]: "
if "!SSL_ORG!"=="" set SSL_ORG=LocalWeb Server

set /p SSL_UNIT="Organizational Unit [IT Department]: "
if "!SSL_UNIT!"=="" set SSL_UNIT=IT Department

set /p SSL_CN="Common Name [!DETECTED_HOSTNAME!]: "
if "!SSL_CN!"=="" set SSL_CN=!DETECTED_HOSTNAME!

set /p SSL_DAYS="Certificate validity (days) [365]: "
if "!SSL_DAYS!"=="" set SSL_DAYS=365

echo.
echo Generating comprehensive SSL certificates...

cd "!SSL_DIR!"

REM Create OpenSSL configuration file
(
echo [req]
echo default_bits = 2048
echo prompt = no
echo default_md = sha256
echo distinguished_name = dn
echo req_extensions = v3_req
echo.
echo [dn]
echo C=!SSL_COUNTRY!
echo ST=!SSL_STATE!
echo L=!SSL_CITY!
echo O=!SSL_ORG!
echo OU=!SSL_UNIT!
echo CN=!SSL_CN!
echo.
echo [v3_req]
echo basicConstraints = CA:FALSE
echo keyUsage = keyEncipherment, dataEncipherment, digitalSignature
echo extendedKeyUsage = serverAuth, clientAuth
echo subjectAltName = @alt_names
echo.
echo [alt_names]
echo DNS.1 = localhost
echo DNS.2 = *.localhost
echo DNS.3 = !SSL_CN!
echo DNS.4 = !DETECTED_HOSTNAME!
echo DNS.5 = !DETECTED_COMPUTERNAME!
echo DNS.6 = *.!DETECTED_HOSTNAME!
echo IP.1 = 127.0.0.1
echo IP.2 = ::1
) > openssl.conf

REM Add detected IPs to SANs
set /a IP_COUNTER=3
for %%i in (!LOCAL_IPS!) do (
    echo IP.!IP_COUNTER! = %%i >> openssl.conf
    set /a IP_COUNTER+=1
)

REM Generate private key
echo Generating private key...
openssl genrsa -out localweb.key 2048 2>nul

REM Generate certificate signing request
echo Generating certificate signing request...
openssl req -new -key localweb.key -out localweb.csr -config openssl.conf 2>nul

REM Generate self-signed certificate
echo Generating self-signed certificate...
openssl x509 -req -days !SSL_DAYS! -in localweb.csr -signkey localweb.key -out localweb.crt -extensions v3_req -extfile openssl.conf 2>nul

REM Generate PKCS#12 file
echo Generating PKCS#12 certificate...
openssl pkcs12 -export -out localweb.pfx -inkey localweb.key -in localweb.crt -passout pass:localweb 2>nul

REM Generate PEM bundle
echo Generating PEM bundle...
copy localweb.crt + localweb.key localweb.pem >nul

REM Verify certificate
openssl x509 -noout -text -in localweb.crt >nul 2>&1
if not errorlevel 1 (
    echo.
    echo ✓ SSL certificates generated successfully!
    echo.
    echo Certificate details:
    echo - Location: !SSL_DIR!\
    echo - Certificate: localweb.crt
    echo - Private Key: localweb.key
    echo - PKCS#12 Bundle: localweb.pfx (password: localweb)
    echo - PEM Bundle: localweb.pem
    echo - Valid for: !SSL_DAYS! days
    echo - Common Name: !SSL_CN!
    echo - Subject Alternative Names:
    openssl x509 -noout -ext subjectAltName -in localweb.crt 2>nul
    
    REM Clean up temporary files
    del localweb.csr openssl.conf >nul 2>&1
    cd "!WORK_DIR!"
    goto :create_utilities
) else (
    echo.
    echo Error: Failed to generate SSL certificates.
    del localweb.key localweb.crt localweb.csr localweb.pfx localweb.pem openssl.conf >nul 2>&1
    echo Falling back to PowerShell PKI method...
    cd "!WORK_DIR!"
    goto :powershell_enhanced
)

:powershell_enhanced
echo.
echo Generating comprehensive SSL certificates using PowerShell PKI...
echo.

REM Auto-detect local information
for /f "tokens=*" %%i in ('hostname') do set "DETECTED_HOSTNAME=%%i"
for /f "tokens=*" %%i in ('echo %COMPUTERNAME%') do set "DETECTED_COMPUTERNAME=%%i"

REM Get local IP addresses
echo Auto-detecting local IP addresses...
set "LOCAL_IPS="
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    set "IP=%%i"
    set "IP=!IP: =!"
    if not "!IP!"=="127.0.0.1" (
        set "LOCAL_IPS=!LOCAL_IPS!!IP! "
    )
)

echo Detected hostname: !DETECTED_HOSTNAME!
echo Detected computer name: !DETECTED_COMPUTERNAME!
echo Detected IP addresses: !LOCAL_IPS!

REM Get certificate details with smart defaults
echo.
echo Enter certificate details (press Enter for detected/default values):
set /p SSL_COUNTRY="Country (2 letter code) [US]: "
if "!SSL_COUNTRY!"=="" set SSL_COUNTRY=US

set /p SSL_STATE="State or Province [Windows]: "
if "!SSL_STATE!"=="" set SSL_STATE=Windows

set /p SSL_CITY="City [LocalCity]: "
if "!SSL_CITY!"=="" set SSL_CITY=LocalCity

set /p SSL_ORG="Organization [LocalWeb Server]: "
if "!SSL_ORG!"=="" set SSL_ORG=LocalWeb Server

set /p SSL_UNIT="Organizational Unit [IT Department]: "
if "!SSL_UNIT!"=="" set SSL_UNIT=IT Department

set /p SSL_CN="Common Name [!DETECTED_HOSTNAME!]: "
if "!SSL_CN!"=="" set SSL_CN=!DETECTED_HOSTNAME!

set /p SSL_DAYS="Certificate validity (days) [365]: "
if "!SSL_DAYS!"=="" set SSL_DAYS=365

echo.
echo Generating comprehensive SSL certificates...

cd "!SSL_DIR!"

REM Create enhanced PowerShell script for certificate generation
(
echo # Enhanced PowerShell PKI Certificate Generation Script
echo $ErrorActionPreference = "Stop"
echo.
echo try {
echo     Write-Host "Detecting local network configuration..."
echo     
echo     # Get local IP addresses
echo     $localIPs = @()
echo     Get-NetIPConfiguration ^| Where-Object {$_.IPv4Address -and $_.IPv4Address.IPAddress -ne "127.0.0.1"} ^| ForEach-Object {
echo         $localIPs += $_.IPv4Address.IPAddress
echo     }
echo.
echo     Write-Host "Found local IPs: $($localIPs -join ', ')"
echo.
echo     # Certificate subject
echo     $subject = "C=!SSL_COUNTRY!, ST=!SSL_STATE!, L=!SSL_CITY!, O=!SSL_ORG!, OU=!SSL_UNIT!, CN=!SSL_CN!"
echo     Write-Host "Certificate subject: $subject"
echo.
echo     # Calculate expiration date
echo     $notAfter = (Get-Date).AddDays(!SSL_DAYS!)
echo     Write-Host "Certificate will expire on: $notAfter"
echo.
echo     # Build Subject Alternative Names
echo     $sanList = @(
echo         "DNS=localhost",
echo         "DNS=*.localhost",
echo         "DNS=!SSL_CN!",
echo         "DNS=!DETECTED_HOSTNAME!",
echo         "DNS=!DETECTED_COMPUTERNAME!",
echo         "DNS=*.!DETECTED_HOSTNAME!",
echo         "IPAddress=127.0.0.1",
echo         "IPAddress=::1"
echo     )
echo.
echo     # Add detected local IPs
echo     foreach ($ip in $localIPs) {
echo         $sanList += "IPAddress=$ip"
echo     }
echo.
echo     $sanExtension = $sanList -join "&"
echo     Write-Host "Subject Alternative Names: $($sanList.Count) entries"
echo.
echo     # Create certificate
echo     Write-Host "Creating certificate with Windows PKI..."
echo     $cert = New-SelfSignedCertificate -Subject $subject -NotAfter $notAfter -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -KeyUsage KeyEncipherment, DigitalSignature -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2", "2.5.29.17={text}$sanExtension") -CertStoreLocation "cert:\CurrentUser\My"
echo.
echo     Write-Host "Certificate created with thumbprint: $($cert.Thumbprint)"
echo.
echo     # Export certificate to PEM format
echo     Write-Host "Exporting certificate to PEM format..."
echo     $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
echo     $certPem = [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
echo     $certPemContent = "-----BEGIN CERTIFICATE-----`n" + $certPem + "`n-----END CERTIFICATE-----"
echo     [System.IO.File]::WriteAllText("localweb.crt", $certPemContent)
echo.
echo     # Export private key to PEM format
echo     Write-Host "Exporting private key to PEM format..."
echo     $keyBytes = $cert.PrivateKey.ExportPkcs8PrivateKey()
echo     $keyPem = [System.Convert]::ToBase64String($keyBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
echo     $keyPemContent = "-----BEGIN PRIVATE KEY-----`n" + $keyPem + "`n-----END PRIVATE KEY-----"
echo     [System.IO.File]::WriteAllText("localweb.key", $keyPemContent)
echo.
echo     # Export PKCS#12 format
echo     Write-Host "Exporting PKCS#12 bundle..."
echo     $pfxBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, "localweb")
echo     [System.IO.File]::WriteAllBytes("localweb.pfx", $pfxBytes)
echo.
echo     # Create PEM bundle
echo     Write-Host "Creating PEM bundle..."
echo     $pemBundle = $certPemContent + "`n" + $keyPemContent
echo     [System.IO.File]::WriteAllText("localweb.pem", $pemBundle)
echo.
echo     # Clean up certificate from store
echo     Write-Host "Cleaning up certificate store..."
echo     Remove-Item "cert:\CurrentUser\My\$($cert.Thumbprint)" -Force
echo.
echo     Write-Host "✓ SSL certificates generated successfully!" -ForegroundColor Green
echo     Write-Host "Certificate valid for !SSL_DAYS! days"
echo     Write-Host "Subject Alternative Names: $($sanList.Count) entries"
echo.
echo } catch {
echo     Write-Host "Error generating certificate: $($_.Exception.Message)" -ForegroundColor Red
echo     Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
echo     exit 1
echo }
) > "generate_cert.ps1"

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "generate_cert.ps1"

if exist "localweb.key" if exist "localweb.crt" (
    del generate_cert.ps1 >nul 2>&1
    echo.
    echo ✓ SSL certificates generated successfully!
    echo.
    echo Certificate details:
    echo - Location: !SSL_DIR!\
    echo - Certificate: localweb.crt
    echo - Private Key: localweb.key
    echo - PKCS#12 Bundle: localweb.pfx (password: localweb)
    echo - PEM Bundle: localweb.pem
    echo - Valid for: !SSL_DAYS! days
    echo - Common Name: !SSL_CN!
    
    REM Display certificate info if OpenSSL is available
    where openssl >nul 2>&1
    if not errorlevel 1 (
        echo - Subject Alternative Names:
        openssl x509 -noout -ext subjectAltName -in localweb.crt 2>nul
    )
    
    cd "!WORK_DIR!"
    goto :create_utilities
) else (
    del generate_cert.ps1 >nul 2>&1
    echo.
    echo Error: Failed to generate SSL certificates.
    echo SSL setup failed. Check PowerShell execution policy and permissions.
    cd "!WORK_DIR!"
    goto :exit
)

:create_utilities
echo.
echo Creating SSL certificate management utilities...

REM Create certificate information script
(
echo @echo off
echo setlocal enabledelayedexpansion
echo.
echo echo ===============================================
echo echo   SSL Certificate Information
echo echo ===============================================
echo echo.
echo.
echo set "SSL_DIR=%%~dp0"
echo set "CERT_FILE=%%SSL_DIR%%localweb.crt"
echo set "KEY_FILE=%%SSL_DIR%%localweb.key"
echo.
echo if not exist "%%CERT_FILE%%" (
echo     echo Certificate file not found: %%CERT_FILE%%
echo     pause
echo     exit /b 1
echo )
echo.
echo where openssl ^>nul 2^>^&1
echo if errorlevel 1 (
echo     echo OpenSSL is not installed. Cannot display certificate information.
echo     pause
echo     exit /b 1
echo )
echo.
echo echo Certificate File: %%CERT_FILE%%
echo echo Private Key File: %%KEY_FILE%%
echo echo.
echo.
echo echo Subject:
echo openssl x509 -noout -subject -in "%%CERT_FILE%%"
echo echo Issuer:
echo openssl x509 -noout -issuer -in "%%CERT_FILE%%"
echo echo Serial Number:
echo openssl x509 -noout -serial -in "%%CERT_FILE%%"
echo echo.
echo.
echo echo Valid From:
echo openssl x509 -noout -startdate -in "%%CERT_FILE%%"
echo echo Valid Until:
echo openssl x509 -noout -enddate -in "%%CERT_FILE%%"
echo echo.
echo.
echo openssl x509 -checkend 0 -noout -in "%%CERT_FILE%%" ^>nul 2^>^&1
echo if not errorlevel 1 (
echo     echo Status: ✓ Certificate is valid
echo ) else (
echo     echo Status: ✗ Certificate is expired
echo )
echo.
echo echo.
echo echo Subject Alternative Names:
echo openssl x509 -noout -ext subjectAltName -in "%%CERT_FILE%%" 2^>nul
echo echo.
echo.
echo echo Key Information:
echo openssl x509 -noout -text -in "%%CERT_FILE%%" ^| findstr "Public Key Algorithm"
echo openssl x509 -noout -text -in "%%CERT_FILE%%" ^| findstr "Public-Key"
echo openssl x509 -noout -text -in "%%CERT_FILE%%" ^| findstr "Signature Algorithm" ^| findstr /n "." ^| findstr "1:"
echo echo.
echo echo ===============================================
echo pause
) > "!SSL_DIR!\cert-info.bat"

REM Create certificate verification script
(
echo @echo off
echo setlocal enabledelayedexpansion
echo title SSL Certificate Verification
echo.
echo echo ===============================================
echo echo   SSL Certificate Verification
echo echo ===============================================
echo echo.
echo.
echo set "SSL_DIR=%%~dp0"
echo set "CERT_FILE=%%SSL_DIR%%localweb.crt"
echo set "KEY_FILE=%%SSL_DIR%%localweb.key"
echo.
echo if not exist "%%CERT_FILE%%" (
echo     echo Certificate file not found: %%CERT_FILE%%
echo     pause
echo     exit /b 1
echo )
echo.
echo if not exist "%%KEY_FILE%%" (
echo     echo Private key file not found: %%KEY_FILE%%
echo     pause
echo     exit /b 1
echo )
echo.
echo where openssl ^>nul 2^>^&1
echo if errorlevel 1 (
echo     echo OpenSSL is not installed. Cannot verify certificate.
echo     echo Please install OpenSSL to use this verification tool.
echo     pause
echo     exit /b 1
echo )
echo.
echo echo Verifying certificate structure...
echo openssl x509 -noout -text -in "%%CERT_FILE%%" ^>nul 2^>^&1
echo if not errorlevel 1 (
echo     echo ✓ Certificate structure is valid
echo ) else (
echo     echo ✗ Certificate structure is invalid
echo     pause
echo     exit /b 1
echo )
echo.
echo echo Verifying private key structure...
echo openssl rsa -noout -text -in "%%KEY_FILE%%" ^>nul 2^>^&1
echo if not errorlevel 1 (
echo     echo ✓ Private key structure is valid
echo ) else (
echo     echo ✗ Private key structure is invalid
echo     pause
echo     exit /b 1
echo )
echo.
echo echo Verifying certificate and key match...
echo for /f "tokens=*" %%i in ('openssl x509 -noout -modulus -in "%%CERT_FILE%%" ^| openssl md5') do set "CERT_HASH=%%i"
echo for /f "tokens=*" %%j in ('openssl rsa -noout -modulus -in "%%KEY_FILE%%" ^| openssl md5') do set "KEY_HASH=%%j"
echo.
echo if "%%CERT_HASH%%"=="%%KEY_HASH%%" (
echo     echo ✓ Certificate and private key match
echo ) else (
echo     echo ✗ Certificate and private key do not match
echo     pause
echo     exit /b 1
echo )
echo.
echo echo Testing HTTPS connection...
echo echo Creating temporary test server...
echo.
echo REM Create temporary Node.js test server
echo (
echo const https = require('https'^);
echo const fs = require('fs'^);
echo const path = require('path'^);
echo.
echo const options = {
echo   key: fs.readFileSync(path.join(__dirname, 'localweb.key'^)^),
echo   cert: fs.readFileSync(path.join(__dirname, 'localweb.crt'^)^)
echo };
echo.
echo const server = https.createServer(options, (req, res^) =^> {
echo   res.writeHead(200, {'Content-Type': 'text/plain'}^);
echo   res.end('SSL Test Server - Certificate is working!\n'^);
echo }^);
echo.
echo server.listen(9443, (^) =^> {
echo   console.log('Test server running on https://localhost:9443'^);
echo   setTimeout((^) =^> {
echo     server.close(^);
echo     process.exit(0^);
echo   }, 3000^);
echo }^);
echo ) ^> test-server.js
echo.
echo where node ^>nul 2^>^&1
echo if not errorlevel 1 (
echo     start /b node test-server.js
echo     timeout /t 2 /nobreak ^>nul
echo     
echo     REM Test connection using PowerShell
echo     powershell -Command "try { $response = Invoke-WebRequest -Uri 'https://localhost:9443' -SkipCertificateCheck -TimeoutSec 5; if ($response.Content -match 'Certificate is working') { Write-Host '✓ HTTPS connection test successful' } else { Write-Host '✗ HTTPS connection test failed' } } catch { Write-Host '✗ HTTPS connection test failed: ' $_.Exception.Message }"
echo     
echo     del test-server.js ^>nul 2^>^&1
echo ) else (
echo     echo Node.js not found. Skipping connection test.
echo     del test-server.js ^>nul 2^>^&1
echo )
echo.
echo echo Certificate verification complete!
echo pause
) > "!SSL_DIR!\verify-cert.bat"

REM Create certificate renewal helper script
(
echo @echo off
echo setlocal enabledelayedexpansion
echo title SSL Certificate Renewal Helper
echo.
echo echo ===============================================
echo echo   SSL Certificate Renewal Helper
echo echo ===============================================
echo echo.
echo.
echo set "SSL_DIR=%%~dp0"
echo set "CERT_FILE=%%SSL_DIR%%localweb.crt"
echo set "KEY_FILE=%%SSL_DIR%%localweb.key"
echo.
echo if not exist "%%CERT_FILE%%" (
echo     echo No existing certificate found.
echo     echo Please run the SSL setup script to create certificates.
echo     pause
echo     exit /b 1
echo )
echo.
echo where openssl ^>nul 2^>^&1
echo if not errorlevel 1 (
echo     echo Checking certificate expiration...
echo     openssl x509 -checkend 2592000 -noout -in "%%CERT_FILE%%" ^>nul 2^>^&1
echo     if not errorlevel 1 (
echo         echo Current certificate is still valid for more than 30 days.
echo         openssl x509 -noout -enddate -in "%%CERT_FILE%%"
echo         echo.
echo         set /p RENEW="Do you want to renew anyway? (y/N): "
echo         if /i "!RENEW!" neq "y" (
echo             echo Certificate renewal cancelled.
echo             pause
echo             exit /b 0
echo         )
echo     ) else (
echo         echo Certificate is expiring soon or already expired.
echo         openssl x509 -noout -enddate -in "%%CERT_FILE%%"
echo         echo Automatic renewal recommended.
echo     )
echo ) else (
echo     echo OpenSSL not found. Cannot check expiration date.
echo )
echo.
echo echo Backing up existing certificates...
echo for /f "tokens=1-6 delims=/: " %%%%a in ('echo %%date%% %%time%%') do set "TIMESTAMP=%%%%c%%%%a%%%%b_%%%%d%%%%e%%%%f"
echo set "TIMESTAMP=!TIMESTAMP: =0!"
echo copy "%%CERT_FILE%%" "%%CERT_FILE%%.backup.!TIMESTAMP!" ^>nul
echo copy "%%KEY_FILE%%" "%%KEY_FILE%%.backup.!TIMESTAMP!" ^>nul
echo echo ✓ Certificates backed up
echo.
echo echo To renew certificates, please run the SSL setup script again:
echo echo   setup-ssl.bat
echo echo.
echo echo Or run the main installer and select the SSL setup option.
echo pause
) > "!SSL_DIR!\renew-cert.bat"

echo ✓ SSL management utilities created:
echo   - cert-info.bat: Display certificate information
echo   - verify-cert.bat: Verify certificate integrity
echo   - renew-cert.bat: Certificate renewal helper

:completion
echo.
echo ===============================================
echo  SSL Certificate Setup Complete!
echo ===============================================
echo.
echo ✓ SSL certificates have been successfully generated.
echo.
echo Files created:
echo - !SSL_DIR!\localweb.crt (Certificate)
echo - !SSL_DIR!\localweb.key (Private Key)
echo - !SSL_DIR!\localweb.pfx (PKCS#12 Bundle)
echo - !SSL_DIR!\localweb.pem (PEM Bundle)
echo - !SSL_DIR!\cert-info.bat (Certificate Info Tool)
echo - !SSL_DIR!\verify-cert.bat (Certificate Verification Tool)
echo - !SSL_DIR!\renew-cert.bat (Certificate Renewal Helper)
echo.
echo Your LocalWeb Server can now use HTTPS on port 8443!
echo Access URLs:
echo   HTTP:  http://localhost:8080
echo   HTTPS: https://localhost:8443
echo.
echo Note: Since this is a self-signed certificate, browsers will show
echo a security warning. This is normal and can be safely ignored for
echo local development.
echo.
echo To view certificate information, run:
echo   !SSL_DIR!\cert-info.bat
echo.
echo To verify certificate integrity, run:
echo   !SSL_DIR!\verify-cert.bat
echo.
echo To check for renewal, run:
echo   !SSL_DIR!\renew-cert.bat
echo.

:exit
echo Press any key to exit...
pause >nul
exit /b 0