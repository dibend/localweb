# LocalWeb Server - Linux Setup Guide

## Issue Resolution

You encountered an error because you ran `install-windows.bat` on a Linux system. The error was:
```
Error: ENOENT: no such file or directory, open 'C:\Program Files\LocalWeb\ssl\localweb.key'
```

## Solution Applied

1. Created SSL certificates in the `ssl/` directory:
   - `ssl/localweb.key` - Private key
   - `ssl/localweb.crt` - Certificate

2. Created the share directory structure as configured in `config.js`:
   - `/workspace/share/`
   - `/workspace/share/Uploads/`

3. Installed Node.js dependencies

## How to Start the Server

### Quick Start
```bash
node server.js
```

### Proper Installation (Recommended)
For a complete installation with all features, run:
```bash
./install.sh
```

## Access the Server

- **HTTP**: http://localhost:8080
- **HTTPS**: https://localhost:8443 (recommended)

### Authentication
- Username: `admin`
- Password: `password123`

## Features

- Browse and download files from the shared directory
- Upload files to the `/Uploads` directory
- Basic authentication for security
- SSL/TLS encryption for HTTPS connections

## Stopping the Server

Press `Ctrl+C` in the terminal where the server is running.

## Configuration

Edit `config.js` to change:
- Share directory path
- Authentication credentials