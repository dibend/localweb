var express = require('express');
var serveIndex = require('serve-index');
var morgan = require('morgan');
var fs = require('fs');
var http = require('http');
var https = require('https');
var compression = require('compression');
var auth = require('basic-auth');
var config = require('./config');
var path = require('path');

var app = express();

app.use(compression());
app.use(morgan('":remote-addr",":date[web]",":method",":url",":status",":response-time ms"'));

// Middleware for Basic Authentication
app.use((req, res, next) => {
  const credentials = auth(req);
  if (!credentials || credentials.name !== config.user || credentials.pass !== config.password) {
    res.setHeader('WWW-Authenticate', 'Basic realm="localweb Access"');
    return res.status(401).send('Access denied');
  }
  next();
});

// Function to generate directory tree structure
function generateDirectoryTree(dir, prefix = '', isLast = true, relativePath = '') {
  let tree = '';
  const items = [];
  
  try {
    const files = fs.readdirSync(dir);
    files.forEach(file => {
      const fullPath = path.join(dir, file);
      const stat = fs.statSync(fullPath);
      items.push({
        name: file,
        isDirectory: stat.isDirectory(),
        path: fullPath,
        relativePath: path.join(relativePath, file)
      });
    });
    
    // Sort directories first, then files
    items.sort((a, b) => {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.localeCompare(b.name);
    });
    
    items.forEach((item, index) => {
      const isLastItem = index === items.length - 1;
      const connector = isLastItem ? '└── ' : '├── ';
      const extension = isLastItem ? '    ' : '│   ';
      
      if (item.isDirectory) {
        tree += `${prefix}${connector}<a href="/${encodeURIComponent(item.relativePath)}/">${item.name}/</a>\n`;
        tree += generateDirectoryTree(item.path, prefix + extension, isLastItem, item.relativePath);
      } else {
        tree += `${prefix}${connector}<a href="/${encodeURIComponent(item.relativePath)}">${item.name}</a>\n`;
      }
    });
  } catch (err) {
    console.error('Error reading directory:', err);
  }
  
  return tree;
}

// Enhanced root page with tree view and upload UI
app.get('/', (req, res) => {
  const shareDir = config.dir;
  const treeHtml = generateDirectoryTree(shareDir);
  
  res.type('html').send(`<!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Share Folder</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
            Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
          line-height: 1.6;
          max-width: 1200px;
          margin: 2rem auto;
          padding: 0 1rem;
        }
        .container {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 2rem;
        }
        @media (max-width: 768px) {
          .container {
            grid-template-columns: 1fr;
          }
        }
        h1 {
          text-align: center;
          margin-bottom: 2rem;
        }
        .section {
          background: #f5f5f5;
          padding: 1.5rem;
          border-radius: 8px;
          height: fit-content;
        }
        .section h2 {
          margin-top: 0;
        }
        .tree-view {
          background: white;
          padding: 1rem;
          border-radius: 4px;
          overflow-x: auto;
          font-family: 'Courier New', monospace;
          white-space: pre;
          line-height: 1.4;
        }
        .tree-view a {
          text-decoration: none;
          color: #0066cc;
        }
        .tree-view a:hover {
          text-decoration: underline;
        }
        #uploadForm {
          background: white;
          padding: 1rem;
          border-radius: 4px;
        }
        input[type="file"] {
          display: block;
          width: 100%;
          margin-bottom: 1rem;
          padding: 0.5rem;
          border: 1px solid #ddd;
          border-radius: 4px;
        }
        button {
          background: #0066cc;
          color: white;
          border: none;
          padding: 0.75rem 1.5rem;
          border-radius: 4px;
          cursor: pointer;
          font-size: 1rem;
          width: 100%;
        }
        button:hover {
          background: #0052a3;
        }
        button:disabled {
          background: #ccc;
          cursor: not-allowed;
        }
        #status {
          margin-top: 1rem;
          padding: 1rem;
          border-radius: 4px;
          display: none;
        }
        #status.success {
          background: #d4edda;
          color: #155724;
          display: block;
        }
        #status.error {
          background: #f8d7da;
          color: #721c24;
          display: block;
        }
        .upload-info {
          margin-top: 1rem;
          padding: 1rem;
          background: #e7f3ff;
          border-radius: 4px;
          font-size: 0.9rem;
          color: #004085;
        }
      </style>
    </head>
    <body>
      <h1>Share Folder Browser</h1>
      
      <div class="container">
        <div class="section">
          <h2>📁 Directory Structure</h2>
          <div class="tree-view">${treeHtml || 'No files or directories found.'}</div>
        </div>
        
        <div class="section">
          <h2>📤 Upload File</h2>
          <div id="uploadForm">
            <input type="file" id="fileInput" />
            <button id="uploadBtn">Upload to Uploads folder</button>
            <div id="status"></div>
            <div class="upload-info">
              <strong>Note:</strong> Files will be uploaded to the <code>/Uploads</code> directory only.
            </div>
          </div>
        </div>
      </div>

      <script>
        (function() {
          const input = document.getElementById('fileInput');
          const statusEl = document.getElementById('status');
          const uploadBtn = document.getElementById('uploadBtn');
          
          uploadBtn.addEventListener('click', async () => {
            if (!input.files.length) {
              statusEl.textContent = 'Please choose a file to upload.';
              statusEl.className = 'error';
              return;
            }

            const file = input.files[0];
            uploadBtn.disabled = true;
            uploadBtn.textContent = 'Uploading...';
            statusEl.className = '';
            statusEl.style.display = 'none';

            try {
              const response = await fetch('/upload/' + encodeURIComponent(file.name), {
                method: 'PUT',
                body: file,
              });

              if (response.ok) {
                statusEl.textContent = '✅ File uploaded successfully to /Uploads/' + file.name;
                statusEl.className = 'success';
                input.value = ''; // Clear the input
                // Refresh the page after 2 seconds to show the new file
                setTimeout(() => {
                  location.reload();
                }, 2000);
              } else {
                const text = await response.text();
                statusEl.textContent = '❌ Upload failed: ' + text;
                statusEl.className = 'error';
              }
            } catch (err) {
              statusEl.textContent = '❌ Error: ' + err.message;
              statusEl.className = 'error';
            } finally {
              uploadBtn.disabled = false;
              uploadBtn.textContent = 'Upload to Uploads folder';
            }
          });
          
          // Allow file upload on Enter key
          input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
              uploadBtn.click();
            }
          });
        })();
      </script>
    </body>
  </html>`);
});

// Simple HTML upload interface served at /upload-ui (kept for backward compatibility)
app.get('/upload-ui', (req, res) => {
  res.redirect('/');
});

// Add PUT endpoint for file uploads to /upload/:filename
app.put('/upload/:filename', (req, res) => {
  const uploadDir = path.join(config.dir, 'Uploads');  // Changed from 'Upload' to 'Uploads'

  // Ensure Uploads directory exists
  if (!fs.existsSync(uploadDir)) {
    try {
      fs.mkdirSync(uploadDir, { recursive: true });
    } catch (err) {
      console.error('Failed to create Uploads directory:', err);
      return res.status(500).send('Server error creating upload directory');
    }
  }

  // Prevent path traversal by using basename only
  const safeFileName = path.basename(req.params.filename);
  const filePath = path.join(uploadDir, safeFileName);

  const writeStream = fs.createWriteStream(filePath);
  req.pipe(writeStream);

  writeStream.on('finish', () => {
    res.status(201).send('File uploaded successfully');
  });

  writeStream.on('error', (err) => {
    console.error('Error writing file:', err);
    res.status(500).send('Error uploading file');
  });
});

// Static file & directory listing middleware (needs to come *after* custom routes)
app.use(express.static(config.dir), serveIndex(config.dir, { icons: true }));

console.log('"ip","date","method","url","status","time"');

// Load SSL credentials only when starting the HTTPS server
function startServers() {
  const sslKey = fs.readFileSync('ssl/localweb.key', 'utf8');
  const sslCert = fs.readFileSync('ssl/localweb.crt', 'utf8');

  const creds = {
    key: sslKey,
    cert: sslCert,
  };

  http.createServer(app).listen(8080, () => {
    console.log('HTTP server listening on port 8080');
  });
  https.createServer(creds, app).listen(8443, () => {
    console.log('HTTPS server listening on port 8443');
  });
}

// Only start the servers if this file is executed directly (e.g. `node server.js`)
if (require.main === module) {
  startServers();
}

module.exports = app;

