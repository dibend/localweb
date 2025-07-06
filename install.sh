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
    echo "  Step 5: SSL Certificate Setup"
    echo "==============================================="
    echo
    
    mkdir -p "$INSTALL_DIR/ssl"
    
    # Check for existing certificates
    if [ -f "$INSTALL_DIR/ssl/localweb.key" ] && [ -f "$INSTALL_DIR/ssl/localweb.crt" ]; then
        print_info "SSL certificates already exist."
        echo
        echo "What would you like to do?"
        echo "1) Use existing certificates"
        echo "2) Generate new self-signed certificates"
        echo "3) Import your own certificates"
        echo
        read -p "Select an option (1-3): " SSL_OPTION
        
        case $SSL_OPTION in
            1)
                print_success "Using existing certificates"
                return 0
                ;;
            2)
                # Continue to generation
                ;;
            3)
                import_certificates
                return 0
                ;;
            *)
                print_error "Invalid option. Using existing certificates."
                return 0
                ;;
        esac
    else
        echo "No SSL certificates found. Let's set them up."
        echo
        echo "What would you like to do?"
        echo "1) Generate new self-signed certificates (recommended)"
        echo "2) Import your own certificates"
        echo "3) Skip SSL setup (not recommended)"
        echo
        read -p "Select an option (1-3): " SSL_OPTION
        
        case $SSL_OPTION in
            1)
                # Continue to generation
                ;;
            2)
                import_certificates
                return 0
                ;;
            3)
                print_warning "Skipping SSL setup. HTTPS will not be available."
                return 0
                ;;
            *)
                print_error "Invalid option. Generating self-signed certificates."
                ;;
        esac
    fi
    
    # Guided certificate generation
    echo
    print_info "Let's generate a self-signed SSL certificate."
    echo
    echo "This certificate will be used to enable HTTPS access to your LocalWeb Server."
    echo "Self-signed certificates will show a security warning in browsers, but are"
    echo "perfectly safe for local/personal use."
    echo
    
    # Collect certificate information
    echo "Please provide the following information for your certificate:"
    echo "(Press Enter to use the default values)"
    echo
    
    # Country
    read -p "Country Code (2 letters, e.g., US, UK, CA) [US]: " CERT_COUNTRY
    CERT_COUNTRY=${CERT_COUNTRY:-US}
    
    # State
    read -p "State or Province [LocalState]: " CERT_STATE
    CERT_STATE=${CERT_STATE:-LocalState}
    
    # City
    read -p "City or Locality [LocalCity]: " CERT_CITY
    CERT_CITY=${CERT_CITY:-LocalCity}
    
    # Organization
    read -p "Organization Name [LocalWeb Server]: " CERT_ORG
    CERT_ORG=${CERT_ORG:-LocalWeb Server}
    
    # Common Name (most important)
    echo
    print_info "Common Name is the domain/hostname you'll use to access the server."
    print_info "Examples: localhost, 192.168.1.100, myserver.local"
    read -p "Common Name [localhost]: " CERT_CN
    CERT_CN=${CERT_CN:-localhost}
    
    # Email (optional)
    read -p "Email Address (optional): " CERT_EMAIL
    
    # Certificate validity
    echo
    read -p "Certificate validity in days [365]: " CERT_DAYS
    CERT_DAYS=${CERT_DAYS:-365}
    
    # Key size
    echo
    echo "Select key size:"
    echo "1) 2048 bits (recommended, faster)"
    echo "2) 4096 bits (more secure, slower)"
    read -p "Select an option [1]: " KEY_SIZE_OPTION
    
    case $KEY_SIZE_OPTION in
        2)
            KEY_SIZE=4096
            ;;
        *)
            KEY_SIZE=2048
            ;;
    esac
    
    # Generate certificate
    echo
    print_info "Generating SSL certificate..."
    
    # Create certificate configuration file
    cat > "$INSTALL_DIR/ssl/cert.conf" << EOF
[req]
default_bits = $KEY_SIZE
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C=$CERT_COUNTRY
ST=$CERT_STATE
L=$CERT_CITY
O=$CERT_ORG
CN=$CERT_CN
${CERT_EMAIL:+emailAddress=$CERT_EMAIL}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CERT_CN
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

    # Add local network IP if available
    LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}' || hostname -I 2>/dev/null | awk '{print $1}')
    if [ ! -z "$LOCAL_IP" ]; then
        echo "IP.3 = $LOCAL_IP" >> "$INSTALL_DIR/ssl/cert.conf"
    fi
    
    # Generate private key and certificate
    openssl req -new -x509 -days $CERT_DAYS -nodes \
        -config "$INSTALL_DIR/ssl/cert.conf" \
        -keyout "$INSTALL_DIR/ssl/localweb.key" \
        -out "$INSTALL_DIR/ssl/localweb.crt" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Set proper permissions
        chmod 600 "$INSTALL_DIR/ssl/localweb.key"
        chmod 644 "$INSTALL_DIR/ssl/localweb.crt"
        
        # Display certificate information
        print_success "SSL certificate generated successfully!"
        echo
        echo "Certificate Details:"
        echo "-------------------"
        openssl x509 -in "$INSTALL_DIR/ssl/localweb.crt" -text -noout | grep -E "Subject:|Not Before:|Not After :|Subject Alternative Name:" -A1
        echo
        
        # Save certificate info for reference
        cat > "$INSTALL_DIR/ssl/certificate-info.txt" << EOF
LocalWeb Server SSL Certificate Information
==========================================
Generated on: $(date)
Valid for: $CERT_DAYS days
Key Size: $KEY_SIZE bits
Common Name: $CERT_CN
Organization: $CERT_ORG

Certificate Location: $INSTALL_DIR/ssl/localweb.crt
Private Key Location: $INSTALL_DIR/ssl/localweb.key

To trust this certificate in your browser:
- Chrome/Edge: Navigate to https://localhost:8443, click "Advanced" and "Proceed to localhost"
- Firefox: Navigate to https://localhost:8443, click "Advanced" and "Accept the Risk and Continue"
- Or import the certificate file into your browser's certificate store
EOF
        
        print_info "Certificate information saved to: $INSTALL_DIR/ssl/certificate-info.txt"
    else
        print_error "Failed to generate SSL certificate"
        return 1
    fi
}

# Import existing certificates
import_certificates() {
    echo
    print_info "Import Existing SSL Certificates"
    echo
    echo "Please provide the paths to your certificate files:"
    echo
    
    # Get certificate file path
    read -p "Path to certificate file (.crt, .pem, or .cer): " CERT_PATH
    if [ ! -f "$CERT_PATH" ]; then
        print_error "Certificate file not found: $CERT_PATH"
        return 1
    fi
    
    # Get private key file path
    read -p "Path to private key file (.key or .pem): " KEY_PATH
    if [ ! -f "$KEY_PATH" ]; then
        print_error "Private key file not found: $KEY_PATH"
        return 1
    fi
    
    # Copy files
    print_info "Importing certificates..."
    cp "$CERT_PATH" "$INSTALL_DIR/ssl/localweb.crt"
    cp "$KEY_PATH" "$INSTALL_DIR/ssl/localweb.key"
    
    # Set proper permissions
    chmod 600 "$INSTALL_DIR/ssl/localweb.key"
    chmod 644 "$INSTALL_DIR/ssl/localweb.crt"
    
    # Verify certificate
    if openssl x509 -in "$INSTALL_DIR/ssl/localweb.crt" -text -noout >/dev/null 2>&1; then
        print_success "Certificates imported successfully!"
        
        # Display certificate info
        echo
        echo "Imported Certificate Details:"
        echo "----------------------------"
        openssl x509 -in "$INSTALL_DIR/ssl/localweb.crt" -text -noout | grep -E "Subject:|Not Before:|Not After :" -A1
    else
        print_error "Invalid certificate file"
        return 1
    fi
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