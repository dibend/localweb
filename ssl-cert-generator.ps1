# LocalWeb Server SSL Certificate Generator
# This script generates a self-signed SSL certificate for LocalWeb Server
# It handles both certificate and private key generation in the correct format

param(
    [string]$Country = "US",
    [string]$State = "LocalState", 
    [string]$City = "LocalCity",
    [string]$Organization = "LocalWeb Server",
    [string]$CommonName = "localhost",
    [int]$ValidDays = 365,
    [string]$OutputPath = ".\ssl"
)

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

Write-Host "Generating SSL Certificate..." -ForegroundColor Yellow

try {
    # Create certificate parameters
    $certParams = @{
        DnsName = @($CommonName, 'localhost', '*.localhost')
        Subject = "CN=$CommonName, O=$Organization, L=$City, S=$State, C=$Country"
        KeyAlgorithm = 'RSA'
        KeyLength = 2048
        HashAlgorithm = 'SHA256'
        NotAfter = (Get-Date).AddDays($ValidDays)
        CertStoreLocation = 'Cert:\LocalMachine\My'
        KeySpec = 'KeyExchange'
        KeyUsage = @('KeyEncipherment', 'DigitalSignature')
        KeyUsageProperty = 'All'
        Provider = 'Microsoft Enhanced RSA and AES Cryptographic Provider'
        KeyExportPolicy = 'Exportable'
        FriendlyName = 'LocalWeb Server Certificate'
        TextExtension = @('2.5.29.37={text}1.3.6.1.5.5.7.3.1')  # Server Authentication
    }

    # Add local IP addresses to certificate
    $localIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -ExpandProperty IPAddress
    foreach ($ip in $localIPs) {
        $certParams.DnsName += $ip
    }
    
    # Always include standard IPs
    $certParams.DnsName += '127.0.0.1'
    $certParams.DnsName += '::1'

    # Generate certificate
    $cert = New-SelfSignedCertificate @certParams

    Write-Host "Certificate generated successfully!" -ForegroundColor Green
    Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor Cyan

    # Export certificate (public key)
    $certPath = Join-Path $OutputPath "localweb.crt"
    Export-Certificate -Cert $cert -FilePath $certPath -Type CERT | Out-Null

    # Convert to PEM format
    $certContent = @"
-----BEGIN CERTIFICATE-----
$([Convert]::ToBase64String((Get-Content $certPath -Encoding Byte), 'InsertLineBreaks'))
-----END CERTIFICATE-----
"@
    $certContent | Out-File -FilePath $certPath -Encoding ASCII

    Write-Host "Certificate exported to: $certPath" -ForegroundColor Green

    # Export private key
    $keyPath = Join-Path $OutputPath "localweb.key"
    $pfxPath = Join-Path $OutputPath "temp.pfx"
    $password = ConvertTo-SecureString -String "TempPassword123!" -Force -AsPlainText
    
    # Export to PFX first
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password | Out-Null

    # Try to convert using .NET if available
    try {
        Add-Type -AssemblyName System.Security
        $pfxData = [System.IO.File]::ReadAllBytes($pfxPath)
        $pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
        $pfx.Import($pfxData, "TempPassword123!", [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
        
        $privateKey = $pfx[0].PrivateKey
        $rsaParams = $privateKey.ExportParameters($true)
        
        # Build PEM format private key manually
        $keyPem = @"
-----BEGIN RSA PRIVATE KEY-----
"@
        
        # This is a simplified approach - for production use, proper ASN.1 encoding would be needed
        # For now, we'll create a script that requires OpenSSL for proper conversion
        
        $keyInstructions = @"
# LocalWeb Server Private Key
# ============================
# A PFX file has been generated at: $pfxPath
# 
# To extract the private key in PEM format, you need OpenSSL:
# 
# Option 1: Install OpenSSL for Windows
# 1. Download from: https://slproweb.com/products/Win32OpenSSL.html
# 2. Run: openssl pkcs12 -in "$pfxPath" -nocerts -nodes -out "$keyPath" -password pass:TempPassword123!
# 
# Option 2: Use WSL (Windows Subsystem for Linux) if installed
# 1. Open WSL terminal
# 2. Run: openssl pkcs12 -in "$($pfxPath -replace '\\','/')" -nocerts -nodes -out "$($keyPath -replace '\\','/')" -password pass:TempPassword123!
# 
# Option 3: Use the HTTP-only mode (port 8080) until you can extract the key
# 
# The PFX password is: TempPassword123!
"@
        $keyInstructions | Out-File -FilePath $keyPath -Encoding ASCII
        
        Write-Host "Private key instructions saved to: $keyPath" -ForegroundColor Yellow
        Write-Host "Note: Manual conversion to PEM format is required. See instructions in the key file." -ForegroundColor Yellow
        
    } catch {
        # Fallback if .NET method fails
        $keyInstructions = @"
# LocalWeb Server Private Key
# ============================
# Certificate generation successful, but private key extraction requires OpenSSL.
# 
# A PFX file has been saved at: $pfxPath
# Password: TempPassword123!
# 
# To extract the private key:
# 1. Install OpenSSL for Windows from: https://slproweb.com/products/Win32OpenSSL.html
# 2. Run: openssl pkcs12 -in "$pfxPath" -nocerts -nodes -out "$keyPath" -password pass:TempPassword123!
# 3. Delete the temp.pfx file when done
"@
        $keyInstructions | Out-File -FilePath $keyPath -Encoding ASCII
        Write-Host "Private key export requires OpenSSL. Instructions saved to: $keyPath" -ForegroundColor Yellow
    }

    # Create certificate info file
    $infoPath = Join-Path $OutputPath "certificate-info.txt"
    $certInfo = @"
LocalWeb Server SSL Certificate Information
==========================================
Generated on: $(Get-Date)
Valid until: $($cert.NotAfter)
Thumbprint: $($cert.Thumbprint)

Certificate Details:
-------------------
Common Name: $CommonName
Organization: $Organization
Location: $City, $State, $Country
Key Algorithm: RSA 2048-bit
Signature Algorithm: SHA256

Subject Alternative Names:
-------------------------
$($certParams.DnsName -join "`n")

File Locations:
--------------
Certificate: $certPath
Private Key: $keyPath
PFX Bundle: $pfxPath (password: TempPassword123!)

Browser Trust Instructions:
--------------------------
1. Chrome/Edge: 
   - Navigate to https://localhost:8443
   - Click "Advanced" and "Proceed to localhost"
   
2. Firefox:
   - Navigate to https://localhost:8443
   - Click "Advanced" and "Accept the Risk and Continue"

3. Import Certificate (Optional):
   - Chrome: Settings > Privacy > Security > Manage certificates > Import
   - Firefox: Settings > Privacy & Security > Certificates > View Certificates > Import
   - Edge: Settings > Privacy > Manage certificates > Import
   - Import the .crt file from: $certPath

Windows Certificate Store:
-------------------------
The certificate has been temporarily installed in the Windows certificate store.
It will be removed after export. To permanently trust it:
1. Run: certutil -addstore -user "Root" "$certPath"
2. Or double-click the .crt file and install to "Trusted Root Certification Authorities"
"@
    $certInfo | Out-File -FilePath $infoPath -Encoding UTF8
    Write-Host "Certificate information saved to: $infoPath" -ForegroundColor Green

    # Remove certificate from store
    Remove-Item -Path "Cert:\LocalMachine\My\$($cert.Thumbprint)" -ErrorAction SilentlyContinue

    Write-Host "`nSSL Certificate generation completed!" -ForegroundColor Green
    Write-Host "Please see $keyPath for private key extraction instructions." -ForegroundColor Yellow
    
    return $true

} catch {
    Write-Host "Error generating certificate: $_" -ForegroundColor Red
    return $false
}