# Local Web
Serves directory over HTTP & HTTPS

Serves directory over HTTP & HTTPS on Ubuntu Server LTS

## Installation

### Method 1: Using Installers (Recommended)

We provide automated installation scripts for easy setup:

#### Windows 11 (64-bit)
```bash
# Right-click and "Run as Administrator"
install-windows.bat
```

#### Unix/Linux/macOS
```bash
# Make the installer executable
chmod +x install.sh

# Run the installer
./install.sh
```

The installers will:
- Check and install Node.js if needed
- Set up the application with dependencies
- Configure authentication credentials
- Runs an interactive SSL Certificate Setup Wizard that generates self-signed certificates
- Create shortcuts and optionally install as a system service
- Configure firewall rules

> **Note:** For detailed installer documentation, troubleshooting, and uninstallation instructions, see [INSTALLERS.md](INSTALLERS.md)

### Method 2: Manual Installation

1. Install dependencies:
```bash
sudo apt-get update
sudo apt-get install -y npm
```

2. Install Node.js:
```bash
sudo apt-get install -y nodejs
```

3. Clone this repository:
```
git clone https://github.com/dibend/localweb.git
```

4. Navigate to the cloned repository:
```
cd localweb
```

5. Install dependencies using npm:
```
npm install
```

6. Create a folder named ssl and add ssl key and cert named localweb.key and localweb.crt:
```bash
mkdir ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/localweb.key -out ssl/localweb.crt
```

## Configuration

Create a configuration file named `config.js` (preferred) **or** `config.json` in the project root with the following structure:

```js
// config.js (recommended – allows comments)
module.exports = {
  // Absolute path to the directory you want to share
  dir: "/home/share",

  // HTTP Basic-Auth credentials
  user: "your_username",
  password: "your_password",
};
```

If you prefer JSON, use the same keys **without** comments:

```json
{
  "dir": "/home/share",
  "user": "your_username",
  "password": "your_password"
}
```

> **Tip:** A sample file is available at `config.sample.json`.

### Starting the server

```bash
node server.js
# or, for live-reload during development
yarn nodemon server.js
```

The application starts two listeners by default:

* **HTTP**  `http://<host>:8080`
* **HTTPS** `https://<host>:8443` (requires `ssl/localweb.key` and `ssl/localweb.crt`)

When you access either URL you will be prompted for the username and password defined in `config.js`.

---

## REST API

| Method | Endpoint                | Description                             | Auth required |
|--------|-------------------------|-----------------------------------------|---------------|
| GET    | `/` / any file path     | Serves static files & directory listing | ✅            |
| PUT    | `/upload/:filename`     | Uploads a file into `<dir>/Upload/`     | ✅            |
| GET    | `/upload-ui`            | Simple HTML form for manual uploading   | ✅            |

### `PUT /upload/:filename`

* **Body:** raw bytes of the file (any content-type)
* **Success Response:** `201 Created` + `File uploaded successfully`
* **Failure Responses:**
  * `401 Unauthorized` when credentials are missing/invalid
  * `500 Internal Server Error` if the server cannot write the file

Example using `curl`:

```bash
curl -u "<user>:<pass>" \
     --upload-file ./picture.jpg \
     "http://localhost:8080/upload/picture.jpg"
```

### `GET /upload-ui`

Opens a minimal web interface to select a local file and upload it to the server without using the command-line. The page performs a `PUT /upload/:filename` request in the background.

---

## Running tests

Unit tests are written with **Jest** and **SuperTest**.

```bash
# install dependencies (including devDependencies)
npm install

# run the test suite
npm test
```

Tests spin up the Express application in-memory (no ports are bound) and verify:

1. Authentication is enforced.
2. Directory listing is served for authorised users.
3. File uploads succeed and are persisted to a temporary directory.

---

## File structure

```
├── server.js            # Main application entry point
├── start.sh             # Helper script (optional)
├── ssl/                 # SSL certificates
├── config.js            # Your personal configuration (not committed)
├── __tests__/           # Jest test suite
└── README.md            # You're reading it
```

---

# OpenSSL Download Script for Windows 11

This batch script automatically downloads OpenSSL from the official FireDaemon source for Windows 11.

## Features

- **Official Source**: Downloads from FireDaemon, the official OpenSSL binary distribution provider for Windows
- **Latest Version**: Downloads OpenSSL 3.5.1 LTS (Long Term Support until April 8, 2030)
- **Multiple Options**: Choose between installer (.exe) or portable ZIP archive
- **Security**: Verifies downloaded files using SHA256 checksums
- **User-Friendly**: Interactive menu with clear instructions
- **Error Handling**: Comprehensive error checking and validation

## System Requirements

- Windows 11 (also compatible with Windows 10 and Windows Server 2016+)
- PowerShell (included with Windows)
- Internet connection
- ~20MB free disk space

## Usage

1. **Download the script**: Save `download_openssl_win11.bat` to your computer
2. **Run the script**: Double-click the batch file or run from Command Prompt
3. **Select download option**:
   - **Option 1**: OpenSSL Installer (Recommended) - Easy installation with automatic setup
   - **Option 2**: ZIP Archive - Portable installation for manual setup
   - **Option 3**: Download both versions
4. **Follow the prompts**: The script will guide you through the process

## Download Options

### Option 1: Installer (Recommended)
- **File**: `FireDaemon-OpenSSL-x64-3.5.1.exe`
- **Size**: ~8MB
- **Benefits**: 
  - Automatic installation and PATH setup
  - Creates program shortcuts
  - Installs to standard Windows directories
  - Easy uninstallation via Control Panel

### Option 2: ZIP Archive (Portable)
- **File**: `openssl-3.5.1.zip`
- **Size**: ~12MB
- **Benefits**:
  - Portable installation
  - Includes x86, x64, and ARM64 binaries
  - No registry modifications
  - Can be used from USB drives

## Manual Installation (ZIP Version)

If you choose the ZIP archive option, follow these steps:

1. Extract the ZIP file to your desired location (e.g., `C:\OpenSSL`)
2. Add the `bin` directory to your system PATH
3. Set the `OPENSSL_CONF` environment variable to point to `ssl\openssl.cnf`

### Setting Environment Variables

**Via Command Prompt (Admin required):**
```cmd
setx OPENSSL_HOME "C:\OpenSSL"
setx OPENSSL_CONF "C:\OpenSSL\ssl\openssl.cnf"
setx PATH "%PATH%;C:\OpenSSL\bin"
```

**Via PowerShell (Admin required):**
```powershell
[Environment]::SetEnvironmentVariable("OPENSSL_HOME", "C:\OpenSSL", "Machine")
[Environment]::SetEnvironmentVariable("OPENSSL_CONF", "C:\OpenSSL\ssl\openssl.cnf", "Machine")
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;C:\OpenSSL\bin", "Machine")
```

## Verification

After installation, verify OpenSSL is working:

```cmd
openssl version -a
```

This should display OpenSSL version information and configuration details.

## Security Notes

- The script uses HTTPS (TLS 1.2) for secure downloads
- All downloads are verified using SHA256 checksums
- Files are downloaded from the official FireDaemon source
- FireDaemon binaries are digitally signed with Extended Validation certificates

## Troubleshooting

### Common Issues

1. **PowerShell Execution Policy**: If PowerShell commands fail, run:
   ```cmd
   powershell -ExecutionPolicy Bypass -File download_openssl_win11.bat
   ```

2. **Administrator Rights**: Some operations may require administrator privileges. Run the script as administrator if needed.

3. **Firewall/Antivirus**: Some security software may block downloads. Temporarily disable or whitelist the script.

4. **Network Issues**: Ensure you have internet connectivity and the FireDaemon servers are accessible.

## Version Information

- **OpenSSL Version**: 3.5.1 LTS
- **Release Date**: April 8, 2025
- **Support Until**: April 8, 2030 (5 years LTS)
- **Source**: FireDaemon Technologies Limited

## Links

- **FireDaemon OpenSSL**: https://www.firedaemon.com/download-firedaemon-openssl
- **Installation Guide**: https://kb.firedaemon.com/support/solutions/articles/4000121705
- **OpenSSL Documentation**: https://www.openssl.org/docs/
- **OpenSSL Official Site**: https://www.openssl.org/

## License

This script is provided as-is. OpenSSL is distributed under the OpenSSL License. FireDaemon's OpenSSL binary distribution is free to use and redistribute.

## Support

For issues with this script, please check the troubleshooting section above. For OpenSSL-related questions, refer to the OpenSSL documentation or community forums.
