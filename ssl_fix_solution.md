# SSL Certificate Fix Solution

## Problem
The Node.js server was failing with the following error:
```
Error: error:0480006C:PEM routines::no start line
```

This error occurred because the server was trying to load SSL certificates from the `ssl/` directory, but the certificates didn't exist or were malformed.

## Root Cause
- The `ssl/` directory was missing from the project
- The required SSL certificate files (`localweb.key` and `localweb.crt`) were not present
- The server's `startServers()` function in `server.js` was trying to load these certificates to create the HTTPS server

## Solution
1. **Created the SSL directory**: `mkdir -p ssl`

2. **Generated self-signed SSL certificates** using OpenSSL:
   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout ssl/localweb.key \
     -out ssl/localweb.crt \
     -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
   ```

3. **Installed Node.js dependencies**: `npm install`

4. **Created the required share directory**: `mkdir -p /workspace/share`

## Result
The server now starts successfully with both HTTP and HTTPS servers:
- HTTP server listening on port 8080
- HTTPS server listening on port 8443

## File Structure
```
ssl/
├── localweb.crt    # SSL certificate (PEM format)
└── localweb.key    # Private key (PEM format)
```

## Notes
- The certificates are self-signed and valid for 365 days
- For production use, you should replace these with certificates from a trusted CA
- The certificates are configured for `localhost` hostname
- The private key has restricted permissions (600) for security