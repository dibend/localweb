# LocalWeb Server Installers Guide

This guide provides detailed information about the automated installation scripts for LocalWeb Server.

## Overview

LocalWeb Server provides automated installation scripts for:
- **Windows 11 (64-bit)**: `install-windows.bat`
- **Unix/Linux/macOS**: `install.sh`

Both installers provide a guided, interactive installation process that handles all setup requirements.

## Windows Installer (`install-windows.bat`)

### Requirements
- Windows 11 64-bit
- Administrator privileges

### What it does
1. **Checks prerequisites**: Verifies Windows version and administrator privileges
2. **Node.js installation**: Checks for Node.js and offers to install it if missing
3. **File installation**: Copies application files to your chosen directory (default: `C:\Program Files\LocalWeb`)
4. **Configuration**: Prompts for share directory, username, and password
5. **SSL certificates**: Interactive guided setup with options to:
   - Generate certificates using OpenSSL (if available) or PowerShell
   - Import existing certificates
   - Configure certificate parameters
   - Helper script (`extract-private-key.bat`) for Windows-specific key extraction
6. **Shortcuts**: Creates desktop and Start Menu shortcuts
7. **Windows Service** (optional): Installs as a Windows service for automatic startup
8. **Firewall rules**: Adds rules for ports 8080 (HTTP) and 8443 (HTTPS)

### Usage
```batch
# Right-click on install-windows.bat and select "Run as administrator"
```

## Unix/Linux/macOS Installer (`install.sh`)

### Requirements
- Unix-like operating system (Linux distributions or macOS)
- bash shell
- sudo access (for some operations)

### Supported Systems
- **Ubuntu/Debian** and derivatives
- **Fedora/RHEL/CentOS** and derivatives
- **Arch Linux/Manjaro**
- **macOS** (requires Homebrew for Node.js installation)
- Other Unix-like systems (with manual Node.js installation)

### What it does
1. **OS detection**: Automatically detects your operating system
2. **Node.js installation**: Checks for Node.js and offers OS-specific installation
3. **File installation**: Copies files to your chosen directory (default: `~/.local/share/localweb`)
4. **Configuration**: Prompts for share directory, username, and password
5. **SSL certificates**: Interactive guided setup for SSL certificates with options to:
   - Generate self-signed certificates with customizable parameters
   - Import existing certificates
   - Configure certificate details (country, organization, common name, etc.)
   - Choose key size (2048/4096 bits) and validity period
   - Automatic Subject Alternative Names (SANs) for multiple hostnames/IPs
6. **Shortcuts**: 
   - Creates command-line shortcut (`localweb` command)
   - Creates desktop entry (Linux only)
   - Adds to PATH if needed
7. **System service** (optional):
   - Linux: Creates systemd service
   - macOS: Creates launchd service
8. **Firewall configuration**: Configures firewall based on your system (ufw, firewalld)

### Usage
```bash
# Make the script executable
chmod +x install.sh

# Run the installer
./install.sh
```

## Installation Options

### Installation Directory
- **Windows default**: `C:\Program Files\LocalWeb`
- **Unix/Linux/macOS default**: `~/.local/share/localweb`
- You can specify a custom directory during installation

### Share Directory
The directory that will be served by LocalWeb:
- **Windows default**: `C:\Users\%USERNAME%\Documents\Share`
- **Unix/Linux/macOS default**: `~/LocalWebShare`
- Creates an `Uploads` subdirectory automatically

### Authentication
- **Default username**: admin
- **Default password**: localweb123 (if no password is provided)
- Strong passwords are recommended for security

### System Service
Installing as a system service allows LocalWeb to:
- Start automatically on system boot
- Run in the background
- Restart automatically if it crashes

## Post-Installation

### Starting the Server

#### Windows
1. Use the desktop shortcut "LocalWeb Server"
2. From Start Menu → LocalWeb → LocalWeb Server
3. If installed as service, it's already running

#### Unix/Linux/macOS
1. Run `localweb` from terminal
2. Run `~/.local/share/localweb/start-localweb.sh`
3. If installed as service, it's already running

### Accessing the Server
- HTTP: `http://localhost:8080`
- HTTPS: `https://localhost:8443`

Use the username and password you configured during installation.

### Service Management

#### Windows Service
```batch
# Stop the service
net stop "LocalWeb Server"

# Start the service
net start "LocalWeb Server"

# Disable automatic startup
sc config "LocalWeb Server" start=manual
```

#### Linux (systemd)
```bash
# Check status
sudo systemctl status localweb

# Stop the service
sudo systemctl stop localweb

# Start the service
sudo systemctl start localweb

# Disable automatic startup
sudo systemctl disable localweb
```

#### macOS (launchd)
```bash
# Stop the service
launchctl unload ~/Library/LaunchAgents/com.localweb.server.plist

# Start the service
launchctl load ~/Library/LaunchAgents/com.localweb.server.plist
```

## Troubleshooting

### Permission Issues
- **Windows**: Ensure you run the installer as Administrator
- **Unix/Linux**: The installer will request sudo access when needed

### Node.js Installation Failed
- Install Node.js manually from https://nodejs.org
- Ensure you have internet connectivity
- Check if your package manager is working correctly

### Firewall Issues
- Manually allow ports 8080 and 8443 in your firewall
- Windows: Check Windows Defender Firewall settings
- Linux: Check ufw/firewalld status
- macOS: Check System Preferences → Security & Privacy → Firewall

### SSL Certificate Issues
- The installer provides guided SSL certificate setup
- For self-signed certificates, browsers will show security warnings - this is normal
- Accept the certificate exception in your browser
- Windows users: If OpenSSL is not available, run `ssl\extract-private-key.bat` to complete setup
- For detailed SSL troubleshooting, see the [SSL Setup Guide](SSL_SETUP_GUIDE.md)

### Service Won't Start
- Check logs:
  - Windows: Event Viewer → Windows Logs → Application
  - Linux: `journalctl -u localweb -f`
  - macOS: `Console.app` → system.log
- Ensure the configuration file is valid
- Check if ports 8080/8443 are already in use

## Uninstallation

### Windows
1. Stop the service if running
2. Remove the service: Run as administrator in the installation directory:
   ```batch
   node uninstall-service.js
   ```
3. Delete the installation directory
4. Remove shortcuts from Desktop and Start Menu

### Unix/Linux/macOS
1. Stop the service if running
2. Remove the service:
   - Linux: `sudo systemctl disable localweb && sudo rm /etc/systemd/system/localweb.service`
   - macOS: `launchctl unload ~/Library/LaunchAgents/com.localweb.server.plist && rm ~/Library/LaunchAgents/com.localweb.server.plist`
3. Delete the installation directory
4. Remove the command from PATH
5. Linux only: Remove desktop entry from `~/.local/share/applications/`

## Security Considerations

1. **Authentication**: Always use strong passwords
2. **SSL/TLS**: The self-signed certificates provide encryption but not identity verification
3. **Firewall**: Only open ports to trusted networks
4. **File Access**: Be careful about which directories you share
5. **Updates**: Keep Node.js and dependencies updated

## Getting Help

If you encounter issues:
1. Check this guide's troubleshooting section
2. Review the main README.md
3. Check existing issues on GitHub
4. Create a new issue with:
   - Your operating system and version
   - Installation method used
   - Error messages
   - Steps to reproduce the problem