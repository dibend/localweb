@echo off
setlocal enabledelayedexpansion
title LocalWeb Server - Private Key Extractor

echo.
echo ===============================================
echo  LocalWeb Server Private Key Extractor
echo ===============================================
echo.
echo This tool helps extract private keys from PFX files.
echo.

:: Check if OpenSSL is available
where openssl >nul 2>&1
if %errorLevel% equ 0 (
    echo OpenSSL detected! Proceeding with extraction...
    echo.
    
    :: Check for PFX file
    if exist "ssl\temp.pfx" (
        set PFX_FILE=ssl\temp.pfx
    ) else (
        echo Enter the path to your PFX file:
        set /p PFX_FILE="> "
        
        if not exist "!PFX_FILE!" (
            echo ERROR: PFX file not found!
            pause
            exit /b 1
        )
    )
    
    :: Extract private key
    echo Extracting private key from: !PFX_FILE!
    openssl pkcs12 -in "!PFX_FILE!" -nocerts -nodes -out "ssl\localweb.key" -password pass:TempPassword123!
    
    if %errorLevel% equ 0 (
        echo.
        echo ✓ Private key extracted successfully!
        echo   Location: ssl\localweb.key
        
        :: Clean up temp PFX if it exists
        if exist "ssl\temp.pfx" (
            echo.
            echo Cleaning up temporary files...
            del "ssl\temp.pfx"
        )
        
        echo.
        echo Your SSL certificate is now ready for use!
    ) else (
        echo.
        echo ERROR: Failed to extract private key.
        echo Please check the PFX password or file integrity.
    )
    
) else (
    echo OpenSSL is not installed on your system.
    echo.
    echo To extract the private key, you have several options:
    echo.
    echo Option 1: Install OpenSSL for Windows
    echo ----------------------------------------
    echo 1. Download OpenSSL from: https://slproweb.com/products/Win32OpenSSL.html
    echo 2. Install it (Light version is sufficient)
    echo 3. Run this script again
    echo.
    echo Option 2: Use Windows Subsystem for Linux (WSL)
    echo ------------------------------------------------
    echo If you have WSL installed:
    echo 1. Open WSL terminal
    echo 2. Navigate to the LocalWeb directory
    echo 3. Run: openssl pkcs12 -in ssl/temp.pfx -nocerts -nodes -out ssl/localweb.key -password pass:TempPassword123!
    echo.
    echo Option 3: Use an online converter (NOT RECOMMENDED)
    echo ---------------------------------------------------
    echo Various online tools can convert PFX to PEM format, but this is
    echo NOT recommended for security reasons as you'd be uploading your
    echo private key to a third-party service.
    echo.
    echo Option 4: Use HTTP-only mode
    echo -----------------------------
    echo You can use LocalWeb Server without HTTPS by accessing:
    echo http://localhost:8080
    echo.
    
    :: Try PowerShell as last resort
    echo Option 5: Try PowerShell method (experimental)
    echo ----------------------------------------------
    echo Would you like to try extracting using PowerShell? (Y/N)
    set /p TRY_PS="> "
    
    if /i "!TRY_PS!"=="Y" (
        echo.
        echo Attempting PowerShell extraction...
        powershell -ExecutionPolicy Bypass -Command "& {
            $pfx = Get-PfxCertificate -FilePath 'ssl\temp.pfx' -Password (ConvertTo-SecureString -String 'TempPassword123!' -AsPlainText -Force)
            $pfx | Export-PfxCertificate -FilePath 'ssl\export.pfx' -Password (ConvertTo-SecureString -String 'none' -AsPlainText -Force) -ChainOption BuildChain
            Write-Host 'Exported to ssl\export.pfx - Manual conversion still required'
        }"
        echo.
        echo PowerShell export completed, but manual conversion is still needed.
    )
)

echo.
pause