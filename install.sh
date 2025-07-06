#!/bin/bash

# LocalWeb Server Installation Script
# Compatible with Unix/Linux/macOS

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
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        OS="freebsd"
    elif [[ "$OSTYPE" == "openbsd"* ]]; then
        OS="openbsd"
    else
        OS="unknown"
    fi
}

# Check if running as root (not recommended)
check_root() {
    if [ "$EUID" -eq 0 ]; then 
        print_warning "Running as root is not recommended for security reasons."
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Welcome message
show_welcome() {
    clear
    echo
    echo "==============================================="
    echo "  LocalWeb Server Installation Wizard"
    echo "  Unix/Linux/macOS Edition"
    echo "==============================================="
    echo
    echo "Welcome to the LocalWeb Server installation wizard."
    echo "This wizard will guide you through the installation process."
    echo
    read -p "Press Enter to continue..."
}

# Check Node.js installation
check_nodejs() {
    clear
    echo
    echo "==============================================="
    echo "  Step 1: Checking Node.js Installation"
    echo "==============================================="
    echo

    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js $NODE_VERSION is already installed."
        return 0
    else
        print_error "Node.js is not installed."
        echo
        read -p "Would you like to install Node.js? (Y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            install_nodejs
        else
            print_error "Node.js is required to run LocalWeb Server."
            echo "Please install Node.js manually and run this installer again."
            exit 1
        fi
    fi
}

# Install Node.js based on OS
install_nodejs() {
    print_info "Installing Node.js..."
    
    case $OS in
        "ubuntu"|"debian")
            # Install Node.js 20.x
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "fedora"|"rhel"|"centos")
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
            sudo yum install -y nodejs
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm nodejs npm
            ;;
        "freebsd")
            sudo pkg install -y node
            ;;
        "openbsd")
            if command -v sudo &> /dev/null; then
                sudo pkg_add -I node
            else
                doas pkg_add -I node
            fi
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install node
            else
                print_error "Homebrew is not installed. Please install Homebrew first:"
                echo "Visit: https://brew.sh"
                exit 1
            fi
            ;;
        *)
            print_error "Automatic Node.js installation not supported for your OS."
            echo "Please install Node.js manually from: https://nodejs.org"
            exit 1
            ;;
    esac
    
    print_success "Node.js installed successfully!"
}

# Choose installation directory
choose_install_dir() {
    clear
    echo
    echo "==============================================="
    echo "  Step 2: Choose Installation Directory"
    echo "==============================================="
    echo
    
    DEFAULT_DIR="$HOME/.local/share/localweb"
    echo "Where would you like to install LocalWeb Server?"
    echo
    echo "Default: $DEFAULT_DIR"
    echo
    read -p "Press Enter to use default or type a custom path: " INSTALL_DIR
    
    if [ -z "$INSTALL_DIR" ]; then
        INSTALL_DIR="$DEFAULT_DIR"
    fi
    
    # Expand ~ to home directory
    INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
    
    echo
    print_info "Installation directory: $INSTALL_DIR"
    echo
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Directory already exists. Existing files will be overwritten."
        read -p "Continue? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
    
    mkdir -p "$INSTALL_DIR"
}

# Copy application files
install_files() {
    clear
    echo
    echo "==============================================="
    echo "  Step 3: Installing Application Files"
    echo "==============================================="
    echo
    
    print_info "Copying application files..."
    
    # Get the directory where the installer is located
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # Copy files, excluding certain directories and files
    if command -v rsync &> /dev/null; then
        rsync -av --exclude='.git' --exclude='node_modules' --exclude='config.js' \
                  --exclude='ssl' --exclude='install.sh' --exclude='install-windows.bat' \
                  "$SCRIPT_DIR/" "$INSTALL_DIR/"
    else
        # Fallback to cp if rsync is not available
        cp -R "$SCRIPT_DIR"/* "$INSTALL_DIR/" 2>/dev/null
        # Clean up files that should be excluded
        rm -rf "$INSTALL_DIR/.git" "$INSTALL_DIR/node_modules" "$INSTALL_DIR/config.js" \
               "$INSTALL_DIR/ssl" "$INSTALL_DIR/install.sh" "$INSTALL_DIR/install-windows.bat" 2>/dev/null
    fi
    
    print_success "Application files copied"
    
    cd "$INSTALL_DIR"
    
    print_info "Installing dependencies..."
    npm install --production
    print_success "Dependencies installed"
}

# Configure the application
configure_app() {
    clear
    echo
    echo "==============================================="
    echo "  Step 4: Configuration"
    echo "==============================================="
    echo
    
    print_info "Let's configure your LocalWeb Server."
    echo
    
    # Share directory
    DEFAULT_SHARE="$HOME/LocalWebShare"
    echo "Enter the directory path you want to share:"
    echo "(Default: $DEFAULT_SHARE)"
    read -p "> " SHARE_DIR
    
    if [ -z "$SHARE_DIR" ]; then
        SHARE_DIR="$DEFAULT_SHARE"
    fi
    
    # Expand ~ to home directory
    SHARE_DIR="${SHARE_DIR/#\~/$HOME}"
    
    # Create share directory if it doesn't exist
    if [ ! -d "$SHARE_DIR" ]; then
        mkdir -p "$SHARE_DIR"
        mkdir -p "$SHARE_DIR/Uploads"
        print_success "Created share directory: $SHARE_DIR"
    fi
    
    # Username
    echo
    echo "Enter username for authentication:"
    echo "(Default: admin)"
    read -p "> " AUTH_USER
    
    if [ -z "$AUTH_USER" ]; then
        AUTH_USER="admin"
    fi
    
    # Password
    echo
    echo "Enter password for authentication:"
    read -s -p "> " AUTH_PASS
    echo
    
    if [ -z "$AUTH_PASS" ]; then
        AUTH_PASS="localweb123"
        print_warning "Using default password: localweb123"
    fi
    
    # Create config.js
    print_info "Creating configuration file..."
    cat > "$INSTALL_DIR/config.js" << EOF
module.exports = {
  dir: '$SHARE_DIR',
  user: '$AUTH_USER',
  password: '$AUTH_PASS'
};
EOF
    
    print_success "Configuration saved"
}

# Create SSL certificates
create_ssl_certs() {
    clear
    echo
    echo "==============================================="
    echo "  Step 5: Full SSL Certificate Setup Wizard"
    echo "==============================================="
    echo
    
    mkdir -p "$INSTALL_DIR/ssl"
    
    # Check for existing certificates
    if [ -f "$INSTALL_DIR/ssl/localweb.key" ] && [ -f "$INSTALL_DIR/ssl/localweb.crt" ]; then
        print_info "SSL certificates already exist."
        echo
        echo "Certificate Information:"
        if command -v openssl &> /dev/null; then
            echo "Subject: $(openssl x509 -noout -subject -in "$INSTALL_DIR/ssl/localweb.crt" 2>/dev/null | sed 's/subject=//')"
            echo "Issuer: $(openssl x509 -noout -issuer -in "$INSTALL_DIR/ssl/localweb.crt" 2>/dev/null | sed 's/issuer=//')"
            echo "Valid until: $(openssl x509 -noout -enddate -in "$INSTALL_DIR/ssl/localweb.crt" 2>/dev/null | sed 's/notAfter=//')"
            echo "SANs: $(openssl x509 -noout -ext subjectAltName -in "$INSTALL_DIR/ssl/localweb.crt" 2>/dev/null | grep -v "X509v3 Subject Alternative Name" | tr -d ' ')"
        fi
        echo
        read -p "Generate new certificates? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo "This wizard will create a comprehensive SSL certificate setup"
    echo "for secure HTTPS connections to your LocalWeb Server."
    echo
    echo "Features included:"
    echo "• Self-signed certificates with proper Subject Alternative Names"
    echo "• Auto-detection of local IP addresses"
    echo "• Certificate validation and verification"
    echo "• Multiple certificate formats (PEM, P12/PFX)"
    echo "• Certificate management utilities"
    echo
    echo "Choose certificate generation method:"
    echo "1) OpenSSL (recommended - full featured)"
    echo "2) Python cryptography (alternative method)"
    echo "3) Skip SSL setup"
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
            print_warning "Skipping SSL setup. HTTPS will not be available."
            return 0
            ;;
        *)
            print_error "Invalid choice. Using OpenSSL method."
            generate_ssl_openssl_enhanced
            ;;
    esac
    
    # Create certificate management utilities
    create_ssl_utilities
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
    
    cd "$INSTALL_DIR/ssl"
    
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
    
    # Set appropriate permissions
    chmod 600 localweb.key localweb.pfx
    chmod 644 localweb.crt
    
    # Verify certificate
    if openssl x509 -noout -text -in localweb.crt >/dev/null 2>&1; then
        print_success "SSL certificates generated successfully!"
        echo
        echo "Certificate details:"
        echo "- Location: $INSTALL_DIR/ssl/"
        echo "- Certificate: localweb.crt"
        echo "- Private Key: localweb.key"
        echo "- PKCS#12 Bundle: localweb.pfx (password: localweb)"
        echo "- Valid for: $SSL_DAYS days"
        echo "- Common Name: $SSL_CN"
        echo "- Subject Alternative Names:"
        openssl x509 -noout -ext subjectAltName -in localweb.crt 2>/dev/null | grep -v "X509v3 Subject Alternative Name" | sed 's/^[ \t]*/  /'
        
        # Clean up temporary files
        rm -f localweb.csr openssl.conf
    else
        print_error "Failed to generate SSL certificates."
        rm -f localweb.key localweb.crt localweb.csr localweb.pfx openssl.conf
        return 1
    fi
    
    cd "$INSTALL_DIR"
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

    cd "$INSTALL_DIR/ssl"

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
        chmod 644 localweb.crt
        rm -f generate_cert.py
        
        print_success "SSL certificates generated successfully!"
        echo
        echo "Certificate details:"
        echo "- Location: $INSTALL_DIR/ssl/"
        echo "- Certificate: localweb.crt"
        echo "- Private Key: localweb.key"
        echo "- PKCS#12 Bundle: localweb.pfx (password: localweb)"
        echo "- Valid for: $SSL_DAYS days"
        echo "- Common Name: $SSL_CN"
        
        # Display certificate info if OpenSSL is available
        if command -v openssl &> /dev/null; then
            echo "- Subject Alternative Names:"
            openssl x509 -noout -ext subjectAltName -in localweb.crt 2>/dev/null | grep -v "X509v3 Subject Alternative Name" | sed 's/^[ \t]*/  /'
        fi
    else
        rm -f generate_cert.py localweb.key localweb.crt localweb.pfx
        print_error "Failed to generate SSL certificates."
        return 1
    fi
    
    cd "$INSTALL_DIR"
}

# Create SSL certificate management utilities
create_ssl_utilities() {
    print_info "Creating SSL certificate management utilities..."
    
    # Create certificate information script
    cat > "$INSTALL_DIR/ssl/cert-info.sh" << 'EOF'
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
days_left=$(openssl x509 -checkend 0 -noout -in "$CERT_FILE" 2>/dev/null && echo $(($(date -d "$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)" +%s) - $(date +%s))) || echo "0")
if [ "$days_left" -gt 0 ]; then
    echo "Days until expiration: $((days_left / 86400))"
else
    echo "Days until expiration: Certificate expired"
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

    # Create certificate renewal script
    cat > "$INSTALL_DIR/ssl/renew-cert.sh" << 'EOF'
#!/bin/bash
# SSL Certificate Renewal Script

SSL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="$SSL_DIR/localweb.crt"
KEY_FILE="$SSL_DIR/localweb.key"

echo "==============================================="
echo "  SSL Certificate Renewal"
echo "==============================================="
echo

if [ ! -f "$CERT_FILE" ]; then
    echo "No existing certificate found. Please run the installer first."
    exit 1
fi

# Check if certificate is expiring soon (within 30 days)
if command -v openssl &> /dev/null; then
    if openssl x509 -checkend 2592000 -noout -in "$CERT_FILE" >/dev/null 2>&1; then
        echo "Current certificate is still valid for more than 30 days."
        echo "Current expiry: $(openssl x509 -noout -enddate -in "$CERT_FILE" | sed 's/notAfter=//')"
        echo
        read -p "Do you want to renew anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Certificate renewal cancelled."
            exit 0
        fi
    else
        echo "Certificate is expiring soon or already expired."
        echo "Current expiry: $(openssl x509 -noout -enddate -in "$CERT_FILE" | sed 's/notAfter=//')"
        echo "Automatic renewal required."
    fi
fi

# Backup existing certificates
echo "Backing up existing certificates..."
cp "$CERT_FILE" "$CERT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
cp "$KEY_FILE" "$KEY_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Re-run certificate generation
echo "Generating new certificate..."
cd "$SSL_DIR/.."
if [ -f "install.sh" ]; then
    # Extract and run just the SSL generation part
    echo "Please run the installer again and select the SSL setup option."
else
    echo "Installer not found. Please run the full installation again."
fi
EOF

    # Create certificate verification script
    cat > "$INSTALL_DIR/ssl/verify-cert.sh" << 'EOF'
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
cert_modulus=$(openssl x509 -noout -modulus -in "$CERT_FILE" | md5sum)
key_modulus=$(openssl rsa -noout -modulus -in "$KEY_FILE" | md5sum)

if [ "$cert_modulus" = "$key_modulus" ]; then
    echo "✓ Certificate and private key match"
else
    echo "✗ Certificate and private key do not match"
    exit 1
fi

# Test HTTPS connection
echo "Testing HTTPS connection..."
echo "Starting temporary server on port 9443..."

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
  console.log('Press Ctrl+C to stop');
});

process.on('SIGINT', () => {
  console.log('\nStopping test server...');
  server.close(() => {
    console.log('Test server stopped');
    process.exit(0);
  });
});
EOFJS

# Run test server in background
if command -v node &> /dev/null; then
    node "$SSL_DIR/test-server.js" &
    TEST_PID=$!
    sleep 2
    
    # Test connection
    if curl -k -s https://localhost:9443 | grep -q "Certificate is working"; then
        echo "✓ HTTPS connection test successful"
    else
        echo "✗ HTTPS connection test failed"
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
    chmod +x "$INSTALL_DIR/ssl/cert-info.sh"
    chmod +x "$INSTALL_DIR/ssl/renew-cert.sh"
    chmod +x "$INSTALL_DIR/ssl/verify-cert.sh"
    
    print_success "SSL management utilities created:"
    echo "  - cert-info.sh: Display certificate information"
    echo "  - renew-cert.sh: Renew expiring certificates"
    echo "  - verify-cert.sh: Verify certificate integrity"
}

# Create start scripts and shortcuts
create_shortcuts() {
    clear
    echo
    echo "==============================================="
    echo "  Step 6: Creating Start Scripts"
    echo "==============================================="
    echo
    
    # Create start script
    print_info "Creating start script..."
    cat > "$INSTALL_DIR/start-localweb.sh" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
node server.js
EOF
    chmod +x "$INSTALL_DIR/start-localweb.sh"
    
    # Create command-line shortcut
    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "$LOCAL_BIN"
    ln -sf "$INSTALL_DIR/start-localweb.sh" "$LOCAL_BIN/localweb"
    
    print_success "Start script created"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        print_info "Adding $LOCAL_BIN to PATH..."
        
        # Detect shell and update appropriate config file
        if [ -n "$ZSH_VERSION" ]; then
            echo "export PATH=\"\$PATH:$LOCAL_BIN\"" >> "$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            echo "export PATH=\"\$PATH:$LOCAL_BIN\"" >> "$HOME/.bashrc"
        fi
        
        print_warning "Please restart your terminal or run: export PATH=\"\$PATH:$LOCAL_BIN\""
    fi
    
    # Create desktop entry for Linux desktop environments
    if [[ "$OS" != "macos" ]] && [ -d "$HOME/.local/share/applications" ]; then
        print_info "Creating desktop shortcut..."
        cat > "$HOME/.local/share/applications/localweb.desktop" << EOF
[Desktop Entry]
Name=LocalWeb Server
Comment=Local file sharing server
Exec=$INSTALL_DIR/start-localweb.sh
Icon=folder-remote
Terminal=true
Type=Application
Categories=Network;FileTransfer;
EOF
        chmod +x "$HOME/.local/share/applications/localweb.desktop"
        print_success "Desktop shortcut created"
    fi
}

# Setup as system service (optional)
setup_service() {
    echo
    read -p "Would you like to install LocalWeb as a system service? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    if [[ "$OS" == "macos" ]]; then
        setup_launchd_service
    else
        setup_systemd_service
    fi
}

# Setup systemd service for Linux
setup_systemd_service() {
    print_info "Creating systemd service..."
    
    SERVICE_FILE="/tmp/localweb.service"
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=LocalWeb Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$(which node) $INSTALL_DIR/server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    sudo mv "$SERVICE_FILE" /etc/systemd/system/localweb.service
    sudo systemctl daemon-reload
    sudo systemctl enable localweb.service
    sudo systemctl start localweb.service
    
    print_success "Systemd service installed and started"
}

# Setup launchd service for macOS
setup_launchd_service() {
    print_info "Creating launchd service..."
    
    PLIST_FILE="$HOME/Library/LaunchAgents/com.localweb.server.plist"
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.localweb.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(which node)</string>
        <string>$INSTALL_DIR/server.js</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
    
    launchctl load "$PLIST_FILE"
    print_success "Launchd service installed and started"
}

# Configure firewall
configure_firewall() {
    clear
    echo
    echo "==============================================="
    echo "  Step 7: Firewall Configuration"
    echo "==============================================="
    echo
    
    case $OS in
        "ubuntu"|"debian")
            if command -v ufw &> /dev/null; then
                print_info "Configuring UFW firewall..."
                sudo ufw allow 8080/tcp comment "LocalWeb HTTP"
                sudo ufw allow 8443/tcp comment "LocalWeb HTTPS"
                print_success "Firewall rules added"
            else
                print_info "UFW not found. Please configure your firewall manually."
            fi
            ;;
        "fedora"|"rhel"|"centos")
            if command -v firewall-cmd &> /dev/null; then
                print_info "Configuring firewalld..."
                sudo firewall-cmd --permanent --add-port=8080/tcp
                sudo firewall-cmd --permanent --add-port=8443/tcp
                sudo firewall-cmd --reload
                print_success "Firewall rules added"
            else
                print_info "firewalld not found. Please configure your firewall manually."
            fi
            ;;
        "macos")
            print_info "macOS firewall configuration may require manual setup."
            print_info "You may need to allow incoming connections when prompted."
            ;;
        *)
            print_info "Please configure your firewall manually to allow ports 8080 and 8443."
            ;;
    esac
}

# Installation complete
show_completion() {
    clear
    echo
    echo "==============================================="
    echo "  Installation Complete!"
    echo "==============================================="
    echo
    print_success "LocalWeb Server has been successfully installed."
    echo
    echo "Installation Details:"
    echo "---------------------"
    echo "Location: $INSTALL_DIR"
    echo "Share Directory: $SHARE_DIR"
    echo "Username: $AUTH_USER"
    echo "Password: ********"
    echo
    echo "Access URLs:"
    echo "---------------------"
    echo "HTTP:  http://localhost:8080"
    echo "HTTPS: https://localhost:8443"
    echo
    echo "You can start the server by:"
    echo "1. Running: localweb"
    echo "2. Running: $INSTALL_DIR/start-localweb.sh"
    
    if systemctl is-active --quiet localweb.service 2>/dev/null; then
        echo "3. The service is already running in the background"
    elif launchctl list | grep -q com.localweb.server 2>/dev/null; then
        echo "3. The service is already running in the background"
    fi
    
    echo
    read -p "Would you like to start the server now? (Y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Starting LocalWeb Server..."
        cd "$INSTALL_DIR"
        node server.js &
        sleep 2
        
        # Try to open browser
        if command -v xdg-open &> /dev/null; then
            xdg-open "http://localhost:8080"
        elif command -v open &> /dev/null; then
            open "http://localhost:8080"
        else
            print_info "Please open http://localhost:8080 in your browser"
        fi
    fi
}

# Main installation flow
main() {
    detect_os
    check_root
    show_welcome
    check_nodejs
    choose_install_dir
    install_files
    configure_app
    create_ssl_certs
    create_shortcuts
    setup_service
    configure_firewall
    show_completion
}

# Run main function
main