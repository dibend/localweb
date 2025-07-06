#!/bin/bash

# Standalone SSL Certificate Setup Script
# For LocalWeb Server - Unix/Linux/macOS Edition
# Version: 2.0 - Full Featured

set -e  # Exit on error

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        else
            OS="linux"
        fi
    else
        OS="unknown"
    fi
}

# Welcome message
show_welcome() {
    clear
    echo
    echo "==============================================="
    echo "  LocalWeb Server SSL Certificate Setup"
    echo "  Full-Featured Certificate Generation"
    echo "==============================================="
    echo
    echo "This script will create a comprehensive SSL certificate setup"
    echo "for your LocalWeb Server with the following features:"
    echo
    echo "• Self-signed certificates with proper Subject Alternative Names"
    echo "• Auto-detection of local IP addresses and hostnames"
    echo "• Certificate validation and verification"
    echo "• Multiple certificate formats (PEM, P12/PFX)"
    echo "• Certificate management utilities"
    echo "• Cross-platform compatibility"
    echo
    read -p "Press Enter to continue..."
}

# Determine working directory
determine_working_dir() {
    # Check if we're in a LocalWeb installation directory
    if [ -f "server.js" ] && [ -f "package.json" ]; then
        WORK_DIR="$(pwd)"
        print_info "Detected LocalWeb installation in current directory"
    else
        # Look for common installation locations
        POSSIBLE_DIRS=(
            "$HOME/.local/share/localweb"
            "$HOME/localweb"
            "/opt/localweb"
            "/usr/local/share/localweb"
        )
        
        for dir in "${POSSIBLE_DIRS[@]}"; do
            if [ -d "$dir" ] && [ -f "$dir/server.js" ]; then
                WORK_DIR="$dir"
                print_info "Found LocalWeb installation at: $WORK_DIR"
                break
            fi
        done
        
        if [ -z "$WORK_DIR" ]; then
            echo "LocalWeb installation not found. Please specify the directory:"
            read -p "Enter LocalWeb directory path: " WORK_DIR
            
            if [ ! -d "$WORK_DIR" ]; then
                print_warning "Directory doesn't exist. Creating: $WORK_DIR"
                mkdir -p "$WORK_DIR"
            fi
        fi
    fi
    
    # Create ssl directory
    SSL_DIR="$WORK_DIR/ssl"
    mkdir -p "$SSL_DIR"
    
    echo "Working directory: $WORK_DIR"
    echo "SSL directory: $SSL_DIR"
}

# Auto-detect local IP addresses for SANs
get_local_ips() {
    local ips=""
    
    # Get primary network interface IP
    if command -v ip &> /dev/null; then
        ips=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -1)
    elif command -v ifconfig &> /dev/null; then
        ips=$(ifconfig | grep -oE 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -oE '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
    fi
    
    # Get all local IPs
    local all_ips=""
    if command -v hostname &> /dev/null; then
        all_ips=$(hostname -I 2>/dev/null || true)
    fi
    
    # Combine and deduplicate
    echo "$ips $all_ips" | tr ' ' '\n' | sort -u | grep -v '^$' | grep -v '127.0.0.1' | head -5
}

# Check for existing certificates
check_existing_certificates() {
    if [ -f "$SSL_DIR/localweb.key" ] && [ -f "$SSL_DIR/localweb.crt" ]; then
        print_info "SSL certificates already exist."
        echo
        echo "Certificate Information:"
        if command -v openssl &> /dev/null; then
            echo "Subject: $(openssl x509 -noout -subject -in "$SSL_DIR/localweb.crt" 2>/dev/null | sed 's/subject=//')"
            echo "Issuer: $(openssl x509 -noout -issuer -in "$SSL_DIR/localweb.crt" 2>/dev/null | sed 's/issuer=//')"
            echo "Valid until: $(openssl x509 -noout -enddate -in "$SSL_DIR/localweb.crt" 2>/dev/null | sed 's/notAfter=//')"
            echo "SANs: $(openssl x509 -noout -ext subjectAltName -in "$SSL_DIR/localweb.crt" 2>/dev/null | grep -v "X509v3 Subject Alternative Name" | tr -d ' ')"
        fi
        echo
        read -p "Generate new certificates? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing certificates."
            create_ssl_utilities
            exit 0
        fi
    fi
}

# Choose SSL method
choose_ssl_method() {
    echo
    echo "Choose certificate generation method:"
    echo "1) OpenSSL (recommended - full featured)"
    echo "2) Python cryptography (alternative method)"
    echo "3) Exit"
    echo
    read -p "Enter your choice (1-3): " SSL_METHOD
    
    case $SSL_METHOD in
        1)
            generate_ssl_openssl_enhanced
            ;;
        2)
            generate_ssl_python_enhanced
            ;;
        3)
            print_info "Exiting SSL setup."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Using OpenSSL method."
            generate_ssl_openssl_enhanced
            ;;
    esac
}

# Enhanced OpenSSL certificate generation
generate_ssl_openssl_enhanced() {
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is not installed."
        
        # Try to install OpenSSL
        case $OS in
            "ubuntu"|"debian")
                print_info "Installing OpenSSL..."
                sudo apt-get update && sudo apt-get install -y openssl
                ;;
            "fedora"|"rhel"|"centos")
                print_info "Installing OpenSSL..."
                sudo yum install -y openssl
                ;;
            "arch"|"manjaro")
                print_info "Installing OpenSSL..."
                sudo pacman -S --noconfirm openssl
                ;;
            "macos")
                if command -v brew &> /dev/null; then
                    print_info "Installing OpenSSL..."
                    brew install openssl
                else
                    print_error "Please install OpenSSL manually or use Homebrew."
                    return 1
                fi
                ;;
        esac
        
        # Check if installation was successful
        if ! command -v openssl &> /dev/null; then
            print_error "OpenSSL installation failed. Trying Python method..."
            generate_ssl_python_enhanced
            return
        fi
    fi
    
    echo
    print_info "Configuring SSL certificate details..."
    echo
    
    # Auto-detect local information
    local detected_hostname=$(hostname 2>/dev/null || echo "localhost")
    local detected_domain=$(dnsdomainname 2>/dev/null || echo "")
    
    # Certificate details with smart defaults
    echo "Enter certificate details (press Enter for detected/default values):"
    echo
    read -p "Country Code (2 letters) [US]: " SSL_COUNTRY
    SSL_COUNTRY=${SSL_COUNTRY:-US}
    
    read -p "State/Province [$(uname -s | tr '[:upper:]' '[:lower:]')]: " SSL_STATE
    SSL_STATE=${SSL_STATE:-$(uname -s | tr '[:upper:]' '[:lower:]')}
    
    read -p "City/Locality [LocalCity]: " SSL_CITY
    SSL_CITY=${SSL_CITY:-LocalCity}
    
    read -p "Organization [LocalWeb Server]: " SSL_ORG
    SSL_ORG=${SSL_ORG:-LocalWeb Server}
    
    read -p "Organizational Unit [IT Department]: " SSL_OU
    SSL_OU=${SSL_OU:-IT Department}
    
    read -p "Common Name [$detected_hostname]: " SSL_CN
    SSL_CN=${SSL_CN:-$detected_hostname}
    
    read -p "Certificate validity (days) [365]: " SSL_DAYS
    SSL_DAYS=${SSL_DAYS:-365}
    
    echo
    print_info "Auto-detecting local IP addresses..."
    
    # Get local IP addresses for SANs
    local_ips=$(get_local_ips)
    
    echo "Detected IP addresses: $local_ips"
    echo "Additional hostnames will include: localhost, *.localhost, $detected_hostname"
    if [ -n "$detected_domain" ]; then
        echo "Domain: $detected_domain"
    fi
    
    echo
    print_info "Generating comprehensive SSL certificates..."
    
    cd "$SSL_DIR"
    
    # Create OpenSSL configuration file
    cat > openssl.conf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=$SSL_COUNTRY
ST=$SSL_STATE
L=$SSL_CITY
O=$SSL_ORG
OU=$SSL_OU
CN=$SSL_CN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
DNS.3 = $SSL_CN
DNS.4 = $detected_hostname
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

    # Add detected IPs to SANs
    local ip_counter=3
    for ip in $local_ips; do
        echo "IP.$ip_counter = $ip" >> openssl.conf
        ((ip_counter++))
    done
    
    # Add domain if detected
    if [ -n "$detected_domain" ]; then
        echo "DNS.5 = $detected_domain" >> openssl.conf
        echo "DNS.6 = *.$detected_domain" >> openssl.conf
    fi
    
    # Generate private key
    print_info "Generating private key..."
    openssl genrsa -out localweb.key 2048 2>/dev/null
    
    # Generate certificate signing request
    print_info "Generating certificate signing request..."
    openssl req -new -key localweb.key -out localweb.csr -config openssl.conf 2>/dev/null
    
    # Generate self-signed certificate
    print_info "Generating self-signed certificate..."
    openssl x509 -req -days $SSL_DAYS -in localweb.csr -signkey localweb.key -out localweb.crt -extensions v3_req -extfile openssl.conf 2>/dev/null
    
    # Generate PKCS#12 file for Windows compatibility
    print_info "Generating PKCS#12 certificate..."
    openssl pkcs12 -export -out localweb.pfx -inkey localweb.key -in localweb.crt -passout pass:localweb 2>/dev/null
    
    # Generate PEM bundle
    print_info "Generating PEM bundle..."
    cat localweb.crt localweb.key > localweb.pem
    
    # Set appropriate permissions
    chmod 600 localweb.key localweb.pfx
    chmod 644 localweb.crt localweb.pem
    
    # Verify certificate
    if openssl x509 -noout -text -in localweb.crt >/dev/null 2>&1; then
        print_success "SSL certificates generated successfully!"
        echo
        echo "Certificate details:"
        echo "- Location: $SSL_DIR/"
        echo "- Certificate: localweb.crt"
        echo "- Private Key: localweb.key"
        echo "- PKCS#12 Bundle: localweb.pfx (password: localweb)"
        echo "- PEM Bundle: localweb.pem"
        echo "- Valid for: $SSL_DAYS days"
        echo "- Common Name: $SSL_CN"
        echo "- Subject Alternative Names:"
        openssl x509 -noout -ext subjectAltName -in localweb.crt 2>/dev/null | grep -v "X509v3 Subject Alternative Name" | sed 's/^[ \t]*/  /'
        
        # Clean up temporary files
        rm -f localweb.csr openssl.conf
    else
        print_error "Failed to generate SSL certificates."
        rm -f localweb.key localweb.crt localweb.csr localweb.pfx localweb.pem openssl.conf
        return 1
    fi
    
    cd "$WORK_DIR"
}

# Enhanced Python certificate generation
generate_ssl_python_enhanced() {
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        print_error "Python is not installed."
        print_info "Please install Python 3 or use the OpenSSL method."
        return 1
    fi
    
    # Determine Python command
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python"
    fi
    
    # Check if cryptography module is available
    if ! $PYTHON_CMD -c "import cryptography" 2>/dev/null; then
        print_info "Installing Python cryptography module..."
        if command -v pip3 &> /dev/null; then
            pip3 install cryptography
        elif command -v pip &> /dev/null; then
            pip install cryptography
        else
            print_error "pip is not available. Please install cryptography manually:"
            echo "pip install cryptography"
            return 1
        fi
    fi
    
    echo
    print_info "Configuring SSL certificate details..."
    echo
    
    # Auto-detect local information
    local detected_hostname=$(hostname 2>/dev/null || echo "localhost")
    
    # Certificate details with smart defaults
    echo "Enter certificate details (press Enter for detected/default values):"
    echo
    read -p "Country Code (2 letters) [US]: " SSL_COUNTRY
    SSL_COUNTRY=${SSL_COUNTRY:-US}

    read -p "State/Province [$(uname -s | tr '[:upper:]' '[:lower:]')]: " SSL_STATE
    SSL_STATE=${SSL_STATE:-$(uname -s | tr '[:upper:]' '[:lower:]')}

    read -p "City/Locality [LocalCity]: " SSL_CITY
    SSL_CITY=${SSL_CITY:-LocalCity}

    read -p "Organization [LocalWeb Server]: " SSL_ORG
    SSL_ORG=${SSL_ORG:-LocalWeb Server}

    read -p "Organizational Unit [IT Department]: " SSL_OU
    SSL_OU=${SSL_OU:-IT Department}

    read -p "Common Name [$detected_hostname]: " SSL_CN
    SSL_CN=${SSL_CN:-$detected_hostname}

    read -p "Certificate validity (days) [365]: " SSL_DAYS
    SSL_DAYS=${SSL_DAYS:-365}

    echo
    print_info "Auto-detecting local IP addresses..."
    
    # Get local IP addresses for SANs
    local_ips=$(get_local_ips)
    
    echo "Detected IP addresses: $local_ips"
    echo "Additional hostnames will include: localhost, *.localhost, $detected_hostname"

    echo
    print_info "Generating comprehensive SSL certificates using Python..."

    cd "$SSL_DIR"

    # Create enhanced Python script for certificate generation
    cat > generate_cert.py << EOF
import datetime
import ipaddress
import socket
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12

def get_local_ips():
    """Get local IP addresses"""
    ips = []
    try:
        # Get primary IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        primary_ip = s.getsockname()[0]
        s.close()
        ips.append(primary_ip)
    except:
        pass
    
    # Get hostname IP
    try:
        hostname = socket.gethostname()
        hostname_ip = socket.gethostbyname(hostname)
        if hostname_ip not in ips:
            ips.append(hostname_ip)
    except:
        pass
    
    return ips

def generate():
    # Generate private key
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )
    
    # Certificate subject
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, u"$SSL_COUNTRY"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"$SSL_STATE"),
        x509.NameAttribute(NameOID.LOCALITY_NAME, u"$SSL_CITY"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"$SSL_ORG"),
        x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, u"$SSL_OU"),
        x509.NameAttribute(NameOID.COMMON_NAME, u"$SSL_CN"),
    ])
    
    # Build Subject Alternative Names
    san_list = [
        x509.DNSName(u"localhost"),
        x509.DNSName(u"*.localhost"),
        x509.DNSName(u"$SSL_CN"),
        x509.DNSName(u"$detected_hostname"),
        x509.IPAddress(ipaddress.IPv4Address("127.0.0.1")),
        x509.IPAddress(ipaddress.IPv6Address("::1")),
    ]
    
    # Add detected local IPs
    local_ips = get_local_ips()
    for ip_str in local_ips:
        try:
            ip = ipaddress.ip_address(ip_str)
            san_list.append(x509.IPAddress(ip))
        except:
            pass
    
    # Create certificate
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(datetime.datetime.utcnow())
        .not_valid_after(datetime.datetime.utcnow() + datetime.timedelta(days=$SSL_DAYS))
        .add_extension(
            x509.SubjectAlternativeName(san_list),
            critical=False,
        )
        .add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True,
        )
        .add_extension(
            x509.KeyUsage(
                digital_signature=True,
                key_encipherment=True,
                data_encipherment=True,
                key_agreement=False,
                key_cert_sign=False,
                crl_sign=False,
                content_commitment=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        )
        .add_extension(
            x509.ExtendedKeyUsage([
                x509.oid.ExtendedKeyUsageOID.SERVER_AUTH,
                x509.oid.ExtendedKeyUsageOID.CLIENT_AUTH,
            ]),
            critical=True,
        )
        .sign(private_key, hashes.SHA256())
    )

    # Write private key
    with open("localweb.key", "wb") as f:
        f.write(
            private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption(),
            )
        )

    # Write certificate
    with open("localweb.crt", "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))
    
    # Write PKCS#12 bundle
    p12_data = pkcs12.serialize_key_and_certificates(
        name=b"localweb",
        key=private_key,
        cert=cert,
        cas=None,
        encryption_algorithm=serialization.BestAvailableEncryption(b"localweb")
    )
    
    with open("localweb.pfx", "wb") as f:
        f.write(p12_data)
    
    # Write PEM bundle
    with open("localweb.pem", "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption(),
        ))
    
    print("SSL certificates generated successfully!")
    print(f"Certificate valid for $SSL_DAYS days")
    print(f"Subject Alternative Names: {len(san_list)} entries")

if __name__ == "__main__":
    generate()
EOF

    # Run Python script
    $PYTHON_CMD generate_cert.py
    
    if [ $? -eq 0 ] && [ -f "localweb.key" ] && [ -f "localweb.crt" ]; then
        chmod 600 localweb.key localweb.pfx
        chmod 644 localweb.crt localweb.pem
        rm -f generate_cert.py
        
        print_success "SSL certificates generated successfully!"
        echo
        echo "Certificate details:"
        echo "- Location: $SSL_DIR/"
        echo "- Certificate: localweb.crt"
        echo "- Private Key: localweb.key"
        echo "- PKCS#12 Bundle: localweb.pfx (password: localweb)"
        echo "- PEM Bundle: localweb.pem"
        echo "- Valid for: $SSL_DAYS days"
        echo "- Common Name: $SSL_CN"
        
        # Display certificate info if OpenSSL is available
        if command -v openssl &> /dev/null; then
            echo "- Subject Alternative Names:"
            openssl x509 -noout -ext subjectAltName -in localweb.crt 2>/dev/null | grep -v "X509v3 Subject Alternative Name" | sed 's/^[ \t]*/  /'
        fi
    else
        rm -f generate_cert.py localweb.key localweb.crt localweb.pfx localweb.pem
        print_error "Failed to generate SSL certificates."
        return 1
    fi
    
    cd "$WORK_DIR"
}

# Create SSL certificate management utilities
create_ssl_utilities() {
    print_info "Creating SSL certificate management utilities..."
    
    # Create certificate information script
    cat > "$SSL_DIR/cert-info.sh" << 'EOF'
#!/bin/bash
# SSL Certificate Information Script

SSL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="$SSL_DIR/localweb.crt"
KEY_FILE="$SSL_DIR/localweb.key"

if [ ! -f "$CERT_FILE" ]; then
    echo "Certificate file not found: $CERT_FILE"
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo "OpenSSL is not installed. Cannot display certificate information."
    exit 1
fi

echo "==============================================="
echo "  SSL Certificate Information"
echo "==============================================="
echo

echo "Certificate File: $CERT_FILE"
echo "Private Key File: $KEY_FILE"
echo

# Basic certificate information
echo "Subject: $(openssl x509 -noout -subject -in "$CERT_FILE" | sed 's/subject=//')"
echo "Issuer: $(openssl x509 -noout -issuer -in "$CERT_FILE" | sed 's/issuer=//')"
echo "Serial Number: $(openssl x509 -noout -serial -in "$CERT_FILE" | sed 's/serial=//')"
echo

# Validity period
echo "Valid From: $(openssl x509 -noout -startdate -in "$CERT_FILE" | sed 's/notBefore=//')"
echo "Valid Until: $(openssl x509 -noout -enddate -in "$CERT_FILE" | sed 's/notAfter=//')"
echo

# Check if certificate is expired
if openssl x509 -checkend 0 -noout -in "$CERT_FILE" >/dev/null 2>&1; then
    echo "Status: ✓ Certificate is valid"
else
    echo "Status: ✗ Certificate is expired"
fi

# Days until expiration
if command -v date &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        exp_date=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
        exp_timestamp=$(date -j -f "%b %d %T %Y %Z" "$exp_date" +%s 2>/dev/null || echo "0")
        current_timestamp=$(date +%s)
        days_left=$(( (exp_timestamp - current_timestamp) / 86400 ))
    else
        # Linux date command
        exp_date=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
        exp_timestamp=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
        current_timestamp=$(date +%s)
        days_left=$(( (exp_timestamp - current_timestamp) / 86400 ))
    fi
    
    if [ "$days_left" -gt 0 ]; then
        echo "Days until expiration: $days_left"
    else
        echo "Days until expiration: Certificate expired"
    fi
fi

echo

# Subject Alternative Names
echo "Subject Alternative Names:"
openssl x509 -noout -ext subjectAltName -in "$CERT_FILE" 2>/dev/null | grep -v "X509v3 Subject Alternative Name" | sed 's/^[ \t]*/  /' || echo "  None"

echo

# Key information
echo "Key Information:"
echo "  Algorithm: $(openssl x509 -noout -text -in "$CERT_FILE" | grep "Public Key Algorithm" | sed 's/.*Public Key Algorithm: //')"
echo "  Key Size: $(openssl x509 -noout -text -in "$CERT_FILE" | grep "Public-Key:" | sed 's/.*Public-Key: (//' | sed 's/ bit)//')"
echo "  Signature Algorithm: $(openssl x509 -noout -text -in "$CERT_FILE" | grep "Signature Algorithm" | head -1 | sed 's/.*Signature Algorithm: //')"

echo
echo "==============================================="
EOF

    # Create certificate verification script
    cat > "$SSL_DIR/verify-cert.sh" << 'EOF'
#!/bin/bash
# SSL Certificate Verification Script

SSL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="$SSL_DIR/localweb.crt"
KEY_FILE="$SSL_DIR/localweb.key"

echo "==============================================="
echo "  SSL Certificate Verification"
echo "==============================================="
echo

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Certificate or key file not found."
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo "OpenSSL is not installed. Cannot verify certificate."
    exit 1
fi

# Verify certificate structure
echo "Verifying certificate structure..."
if openssl x509 -noout -text -in "$CERT_FILE" >/dev/null 2>&1; then
    echo "✓ Certificate structure is valid"
else
    echo "✗ Certificate structure is invalid"
    exit 1
fi

# Verify private key structure
echo "Verifying private key structure..."
if openssl rsa -noout -text -in "$KEY_FILE" >/dev/null 2>&1; then
    echo "✓ Private key structure is valid"
else
    echo "✗ Private key structure is invalid"
    exit 1
fi

# Verify certificate and key match
echo "Verifying certificate and key match..."
if command -v md5sum &> /dev/null; then
    cert_modulus=$(openssl x509 -noout -modulus -in "$CERT_FILE" | md5sum)
    key_modulus=$(openssl rsa -noout -modulus -in "$KEY_FILE" | md5sum)
elif command -v md5 &> /dev/null; then
    cert_modulus=$(openssl x509 -noout -modulus -in "$CERT_FILE" | md5)
    key_modulus=$(openssl rsa -noout -modulus -in "$KEY_FILE" | md5)
else
    echo "No MD5 utility available. Skipping modulus check."
    cert_modulus="skip"
    key_modulus="skip"
fi

if [ "$cert_modulus" = "$key_modulus" ]; then
    echo "✓ Certificate and private key match"
else
    echo "✗ Certificate and private key do not match"
    exit 1
fi

# Test HTTPS connection if Node.js is available
if command -v node &> /dev/null; then
    echo "Testing HTTPS connection..."
    
    # Create temporary server config
    cat > "$SSL_DIR/test-server.js" << 'EOFJS'
const https = require('https');
const fs = require('fs');
const path = require('path');

const options = {
  key: fs.readFileSync(path.join(__dirname, 'localweb.key')),
  cert: fs.readFileSync(path.join(__dirname, 'localweb.crt'))
};

const server = https.createServer(options, (req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('SSL Test Server - Certificate is working!\n');
});

server.listen(9443, () => {
  console.log('Test server running on https://localhost:9443');
  setTimeout(() => {
    server.close();
    process.exit(0);
  }, 2000);
});
EOFJS

    # Run test server
    node "$SSL_DIR/test-server.js" &
    TEST_PID=$!
    sleep 1
    
    # Test connection
    if command -v curl &> /dev/null; then
        if curl -k -s https://localhost:9443 | grep -q "Certificate is working"; then
            echo "✓ HTTPS connection test successful"
        else
            echo "✗ HTTPS connection test failed"
        fi
    else
        echo "curl not available. Skipping connection test."
    fi
    
    # Clean up
    kill $TEST_PID 2>/dev/null
    rm -f "$SSL_DIR/test-server.js"
else
    echo "Node.js not found. Skipping connection test."
fi

echo
echo "Certificate verification complete!"
EOF

    # Make scripts executable
    chmod +x "$SSL_DIR/cert-info.sh"
    chmod +x "$SSL_DIR/verify-cert.sh"
    
    print_success "SSL management utilities created:"
    echo "  - cert-info.sh: Display certificate information"
    echo "  - verify-cert.sh: Verify certificate integrity"
    echo "  - Run: $SSL_DIR/cert-info.sh"
    echo "  - Run: $SSL_DIR/verify-cert.sh"
}

# Show completion message
show_completion() {
    echo
    echo "==============================================="
    echo "  SSL Certificate Setup Complete!"
    echo "==============================================="
    echo
    print_success "SSL certificates have been successfully generated."
    echo
    echo "Files created:"
    echo "- $SSL_DIR/localweb.crt (Certificate)"
    echo "- $SSL_DIR/localweb.key (Private Key)"
    echo "- $SSL_DIR/localweb.pfx (PKCS#12 Bundle)"
    echo "- $SSL_DIR/localweb.pem (PEM Bundle)"
    echo "- $SSL_DIR/cert-info.sh (Certificate Info Tool)"
    echo "- $SSL_DIR/verify-cert.sh (Certificate Verification Tool)"
    echo
    echo "Your LocalWeb Server can now use HTTPS on port 8443!"
    echo "Access URLs:"
    echo "  HTTP:  http://localhost:8080"
    echo "  HTTPS: https://localhost:8443"
    echo
    echo "Note: Since this is a self-signed certificate, browsers will show"
    echo "a security warning. This is normal and can be safely ignored for"
    echo "local development."
    echo
    echo "To view certificate information, run:"
    echo "  $SSL_DIR/cert-info.sh"
    echo
    echo "To verify certificate integrity, run:"
    echo "  $SSL_DIR/verify-cert.sh"
}

# Main execution
main() {
    detect_os
    show_welcome
    determine_working_dir
    check_existing_certificates
    choose_ssl_method
    create_ssl_utilities
    show_completion
}

# Run main function
main "$@"