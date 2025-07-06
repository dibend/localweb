# LocalWeb Server - Full-Fledged SSL Certificate Setup

## Overview

LocalWeb Server now includes a comprehensive SSL certificate generation system that provides production-ready HTTPS support with proper security configurations. This system has been completely redesigned to offer enterprise-grade features while maintaining ease of use.

## Features

### 🔐 **Comprehensive Certificate Generation**
- **Self-signed certificates** with proper X.509 extensions
- **Subject Alternative Names (SANs)** for multiple hostnames and IP addresses
- **Auto-detection** of local network configuration
- **Multiple certificate formats**: PEM, PKCS#12 (P12/PFX), PEM bundles
- **Cross-platform compatibility** for Windows, Linux, and macOS

### 🌐 **Network-Aware Configuration**
- **Automatic IP detection** for local network interfaces
- **Hostname resolution** and domain detection
- **IPv4 and IPv6 support** in certificate SANs
- **Dynamic network configuration** adaptation

### 🛠️ **Certificate Management Tools**
- **Certificate information viewer** (`cert-info.sh` / `cert-info.bat`)
- **Certificate verification** (`verify-cert.sh` / `verify-cert.bat`)
- **Renewal helpers** (`renew-cert.sh` / `renew-cert.bat`)
- **Automated testing** with built-in HTTPS server validation

### 🔧 **Multiple Generation Methods**
- **OpenSSL** (recommended) - Full-featured certificate generation
- **Python cryptography** - Alternative cross-platform method
- **PowerShell PKI** (Windows) - Native Windows certificate generation
- **Automatic fallback** between methods

## Installation Methods

### Method 1: Integrated Installation (Recommended)

The SSL setup is now fully integrated into the main installers:

#### Unix/Linux/macOS:
```bash
./install.sh
```

#### Windows:
```cmd
install-windows.bat
```

Both installers will automatically:
1. Install required dependencies (OpenSSL, Python cryptography)
2. Generate comprehensive SSL certificates
3. Create certificate management utilities
4. Configure proper file permissions

### Method 2: Standalone SSL Setup

For existing installations or SSL-only setup:

#### Unix/Linux/macOS:
```bash
./setup-ssl.sh
```

#### Windows:
```cmd
setup-ssl.bat
```

## SSL Directory Structure

After installation, your SSL directory will contain:

```
ssl/
├── localweb.crt          # X.509 certificate (PEM format)
├── localweb.key          # Private key (PEM format)
├── localweb.pfx          # PKCS#12 bundle (password: localweb)
├── localweb.pem          # Combined PEM bundle (cert + key)
├── cert-info.sh/.bat     # Certificate information tool
├── verify-cert.sh/.bat   # Certificate verification tool
└── renew-cert.sh/.bat    # Certificate renewal helper
```

## Certificate Features

### Subject Alternative Names (SANs)

The generated certificates include comprehensive SANs for maximum compatibility:

- `localhost` and `*.localhost`
- System hostname and `*.hostname`
- Computer name (Windows)
- All detected local IP addresses
- IPv6 localhost (`::1`)
- Domain names (if detected)

### Security Configuration

- **2048-bit RSA keys** for strong encryption
- **SHA-256 signature algorithm** for modern security
- **Proper key usage extensions** (Digital Signature, Key Encipherment)
- **Extended key usage** for both server and client authentication
- **Basic constraints** properly configured

### Certificate Validity

- **Default validity**: 365 days
- **Customizable validity period** during generation
- **Expiration monitoring** with automatic alerts
- **Backup and renewal** system

## Usage

### Starting the Server

The server automatically detects and uses SSL certificates:

```bash
node server.js
```

Access URLs:
- **HTTP**: `http://localhost:8080`
- **HTTPS**: `https://localhost:8443`

### Certificate Management

#### View Certificate Information
```bash
# Unix/Linux/macOS
./ssl/cert-info.sh

# Windows
ssl\cert-info.bat
```

#### Verify Certificate Integrity
```bash
# Unix/Linux/macOS
./ssl/verify-cert.sh

# Windows
ssl\verify-cert.bat
```

#### Check for Renewal
```bash
# Unix/Linux/macOS
./ssl/renew-cert.sh

# Windows
ssl\renew-cert.bat
```

## Server Configuration

The server automatically supports multiple certificate formats:

### PEM Format (Primary)
```javascript
const options = {
  key: fs.readFileSync('ssl/localweb.key'),
  cert: fs.readFileSync('ssl/localweb.crt')
};
```

### PKCS#12 Format (Fallback)
```javascript
const options = {
  pfx: fs.readFileSync('ssl/localweb.pfx'),
  passphrase: 'localweb'
};
```

## Browser Compatibility

### Self-Signed Certificate Warnings

Since these are self-signed certificates, browsers will display security warnings. This is normal and expected behavior.

#### Chrome/Edge
1. Click "Advanced"
2. Click "Proceed to localhost (unsafe)"

#### Firefox
1. Click "Advanced"
2. Click "Accept the Risk and Continue"

#### Safari
1. Click "Show Details"
2. Click "visit this website"
3. Click "Visit Website"

### Production Considerations

For production environments, consider:
- Using certificates from a trusted Certificate Authority (CA)
- Implementing proper certificate chain validation
- Regular certificate rotation and monitoring

## Troubleshooting

### Common Issues

#### 1. OpenSSL Not Found
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install openssl

# macOS
brew install openssl

# Windows
winget install ShiningLight.OpenSSL
```

#### 2. Python Cryptography Module Missing
```bash
pip install cryptography
```

#### 3. Certificate Generation Failed
- Check file permissions in the SSL directory
- Ensure sufficient disk space
- Verify OpenSSL/Python installation
- Try alternative generation method

#### 4. HTTPS Connection Refused
- Verify certificate files exist and are readable
- Check server configuration
- Ensure port 8443 is not blocked by firewall

### File Permissions

Ensure proper file permissions after generation:

#### Unix/Linux/macOS
```bash
chmod 600 ssl/localweb.key ssl/localweb.pfx
chmod 644 ssl/localweb.crt ssl/localweb.pem
chmod +x ssl/*.sh
```

#### Windows
Use the built-in utilities which set permissions automatically.

## Advanced Configuration

### Custom Certificate Parameters

Both installers support customization of:
- **Country Code** (C)
- **State/Province** (ST)
- **City/Locality** (L)
- **Organization** (O)
- **Organizational Unit** (OU)
- **Common Name** (CN)
- **Validity Period** (days)

### Manual Certificate Generation

For advanced users, certificates can be generated manually using OpenSSL:

```bash
# Generate private key
openssl genrsa -out localweb.key 2048

# Create certificate signing request
openssl req -new -key localweb.key -out localweb.csr -config openssl.conf

# Generate self-signed certificate
openssl x509 -req -days 365 -in localweb.csr -signkey localweb.key -out localweb.crt -extensions v3_req -extfile openssl.conf

# Create PKCS#12 bundle
openssl pkcs12 -export -out localweb.pfx -inkey localweb.key -in localweb.crt -passout pass:localweb
```

## Security Considerations

### Private Key Protection
- Private keys are stored with restrictive permissions (600)
- PKCS#12 files use the password "localweb" (change for production)
- Keys are generated locally and never transmitted

### Certificate Validation
- Built-in verification tools validate certificate integrity
- Automatic key-certificate pairing verification
- Expiration monitoring and alerts

### Network Security
- Certificates include all local network interfaces
- Wildcard entries for flexible hostname matching
- IPv6 support for modern network configurations

## Development vs Production

### Development Environment
- Self-signed certificates are acceptable
- Browser warnings can be safely ignored
- Focus on functionality and testing

### Production Environment
- Use certificates from trusted CAs
- Implement proper certificate chain validation
- Set up automated certificate renewal
- Monitor certificate expiration
- Use proper certificate storage and access controls

## Support and Documentation

### Getting Help
1. Check this README for common solutions
2. Verify system requirements and dependencies
3. Test with the verification tools
4. Check server logs for detailed error messages

### System Requirements
- **Node.js**: Version 14 or higher
- **OpenSSL**: Latest stable version (recommended)
- **Python**: Version 3.6+ with cryptography module (alternative)
- **PowerShell**: Version 5+ (Windows alternative)

### Compatibility
- **Operating Systems**: Windows 10+, Ubuntu 18.04+, macOS 10.14+
- **Browsers**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Node.js**: 14.x, 16.x, 18.x, 20.x

## Version History

### Version 2.0 (Current)
- Complete SSL system redesign
- Auto-detection of network configuration
- Multiple certificate formats
- Comprehensive management utilities
- Cross-platform compatibility improvements
- Enhanced security configurations

### Version 1.x
- Basic SSL certificate generation
- OpenSSL-only support
- Limited SAN configuration
- Manual certificate management

---

**Note**: This SSL setup is designed for development and local network use. For production deployments, consider using certificates from a trusted Certificate Authority and implementing proper certificate management practices.