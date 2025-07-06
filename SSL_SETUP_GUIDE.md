# SSL Certificate Setup Guide for LocalWeb Server

This guide explains how to set up SSL certificates for LocalWeb Server to enable HTTPS access.

## Table of Contents
- [Overview](#overview)
- [Automatic Setup via Installers](#automatic-setup-via-installers)
- [Manual Certificate Generation](#manual-certificate-generation)
- [Using Your Own Certificates](#using-your-own-certificates)
- [Troubleshooting](#troubleshooting)
- [Browser Trust Instructions](#browser-trust-instructions)

## Overview

LocalWeb Server supports HTTPS through SSL/TLS certificates. The installers provide a guided setup process for generating self-signed certificates or importing your own.

### Certificate Requirements
- Certificate file: `ssl/localweb.crt` (PEM format)
- Private key file: `ssl/localweb.key` (PEM format)
- HTTPS runs on port 8443 by default

## Automatic Setup via Installers

### Linux/macOS Installation

The `install.sh` script includes a comprehensive SSL setup wizard:

```bash
./install.sh
```

During Step 5 (SSL Certificate Setup), you'll be presented with options to:
1. Generate new self-signed certificates (recommended for first-time setup)
2. Import your own certificates
3. Skip SSL setup (not recommended)

The installer will guide you through:
- Certificate details (country, organization, etc.)
- Common Name (hostname/IP for accessing the server)
- Certificate validity period
- Key size selection (2048 or 4096 bits)

### Windows Installation

The `install-windows.bat` script includes SSL setup:

```batch
install-windows.bat
```

During Step 5, you can:
1. Generate certificates using OpenSSL (if installed)
2. Generate certificates using PowerShell (Windows 11)
3. Import existing certificates

**Note for Windows users**: If OpenSSL is not installed, the installer uses PowerShell to generate certificates. You may need to run the `extract-private-key.bat` helper script to complete the setup.

## Manual Certificate Generation

### Using OpenSSL (All Platforms)

1. Create the SSL directory:
   ```bash
   mkdir -p ssl
   ```

2. Generate a private key and certificate:
   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout ssl/localweb.key \
     -out ssl/localweb.crt \
     -subj "/C=US/ST=State/L=City/O=LocalWeb/CN=localhost"
   ```

3. For a more detailed certificate with Subject Alternative Names:
   ```bash
   # Create a config file
   cat > ssl/cert.conf << EOF
   [req]
   default_bits = 2048
   prompt = no
   default_md = sha256
   distinguished_name = dn
   x509_extensions = v3_req

   [dn]
   C=US
   ST=YourState
   L=YourCity
   O=YourOrganization
   CN=localhost

   [v3_req]
   subjectAltName = @alt_names

   [alt_names]
   DNS.1 = localhost
   DNS.2 = *.localhost
   IP.1 = 127.0.0.1
   IP.2 = ::1
   EOF

   # Generate certificate
   openssl req -new -x509 -days 365 -nodes \
     -config ssl/cert.conf \
     -keyout ssl/localweb.key \
     -out ssl/localweb.crt
   ```

### Using PowerShell (Windows)

Run the provided PowerShell script:
```powershell
.\ssl-cert-generator.ps1 -CommonName "localhost" -ValidDays 365
```

Then extract the private key:
```batch
.\extract-private-key.bat
```

## Using Your Own Certificates

If you have existing SSL certificates (e.g., from Let's Encrypt or a CA):

1. Copy your certificate to `ssl/localweb.crt`
2. Copy your private key to `ssl/localweb.key`
3. Ensure proper file permissions:
   - Linux/macOS: `chmod 600 ssl/localweb.key`
   - Windows: Right-click → Properties → Security → Adjust as needed

### Certificate Formats

LocalWeb Server expects PEM format. If your certificates are in different formats:

**DER to PEM:**
```bash
openssl x509 -inform der -in certificate.cer -out certificate.pem
```

**PFX/P12 to PEM:**
```bash
# Extract certificate
openssl pkcs12 -in certificate.pfx -clcerts -nokeys -out certificate.pem

# Extract private key
openssl pkcs12 -in certificate.pfx -nocerts -nodes -out private.key
```

## Troubleshooting

### Common Issues

1. **"Error: ENOENT: no such file or directory" when starting server**
   - Ensure the `ssl` directory exists
   - Check that both `localweb.crt` and `localweb.key` files are present

2. **"Error: error:0906D06C:PEM routines:PEM_read_bio:no start line"**
   - Certificate files are not in PEM format
   - Check for proper PEM headers (`-----BEGIN CERTIFICATE-----`)

3. **Browser shows "NET::ERR_CERT_AUTHORITY_INVALID"**
   - This is normal for self-signed certificates
   - Follow browser-specific instructions to proceed

4. **Windows: Private key not extracted properly**
   - Install OpenSSL for Windows
   - Run `extract-private-key.bat`
   - Or use HTTP-only mode (port 8080)

### Regenerating Certificates

To regenerate certificates:
1. Delete existing files: `rm ssl/localweb.*`
2. Run the installer again, or
3. Use manual generation commands above

## Browser Trust Instructions

### Chrome/Edge
1. Navigate to https://localhost:8443
2. Click "Advanced"
3. Click "Proceed to localhost (unsafe)"

To permanently trust:
1. Export certificate from browser
2. Import to system certificate store
3. Mark as trusted for SSL

### Firefox
1. Navigate to https://localhost:8443
2. Click "Advanced"
3. Click "Accept the Risk and Continue"

To permanently trust:
1. Go to Settings → Privacy & Security → Certificates
2. Click "View Certificates"
3. Import `ssl/localweb.crt`
4. Check "Trust this CA to identify websites"

### Safari (macOS)
1. Double-click `ssl/localweb.crt`
2. Add to Keychain (login)
3. Open Keychain Access
4. Find the certificate
5. Double-click and set to "Always Trust"

### System-wide Trust

**Linux:**
```bash
sudo cp ssl/localweb.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

**macOS:**
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ssl/localweb.crt
```

**Windows:**
```batch
certutil -addstore -user "Root" ssl\localweb.crt
```

## Security Considerations

1. **Self-signed certificates** are suitable for:
   - Local development
   - Internal networks
   - Personal use

2. **For production use**, consider:
   - Certificates from a trusted CA
   - Let's Encrypt for free certificates
   - Proper domain names instead of IP addresses

3. **Keep private keys secure**:
   - Never share private keys
   - Use appropriate file permissions
   - Rotate certificates periodically

## Additional Resources

- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Let's Encrypt](https://letsencrypt.org/) - Free SSL certificates
- [SSL Labs](https://www.ssllabs.com/ssltest/) - SSL configuration testing

For more help, please refer to the project documentation or submit an issue on the project repository.