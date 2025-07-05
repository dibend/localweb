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

// Ensure Upload directory exists on startup
const uploadDir = path.join(config.dir, 'Upload');
if (!fs.existsSync(uploadDir)) {
  try {
    fs.mkdirSync(uploadDir, { recursive: true });
    console.log('Created Upload directory:', uploadDir);
  } catch (err) {
    console.error('Failed to create Upload directory:', err);
  }
}

// Middleware for Basic Authentication
app.use((req, res, next) => {
  const credentials = auth(req);
  if (!credentials || credentials.name !== config.user || credentials.pass !== config.password) {
    res.setHeader('WWW-Authenticate', 'Basic realm="localweb Access"');
    return res.status(401).send('Access denied');
  }
  next();
});

// Function to get directory tree structure
function getDirectoryTree(dirPath, relativePath = '') {
  const items = [];
  try {
    const files = fs.readdirSync(dirPath);
    
    for (const file of files) {
      const fullPath = path.join(dirPath, file);
      const relPath = path.join(relativePath, file);
      
      try {
        const stats = fs.statSync(fullPath);
        
        if (stats.isDirectory()) {
          items.push({
            name: file,
            path: relPath,
            type: 'directory',
            children: getDirectoryTree(fullPath, relPath)
          });
        }
      } catch (err) {
        // Skip files/directories we can't access
      }
    }
  } catch (err) {
    console.error('Error reading directory:', err);
  }
  
  return items;
}

// API endpoint to get directory structure
app.get('/api/directory-tree', (req, res) => {
  try {
    const tree = getDirectoryTree(config.dir);
    res.json({ root: config.dir, tree });
  } catch (err) {
    res.status(500).json({ error: 'Failed to read directory structure' });
  }
});

// Simple HTML upload interface served at /upload-ui
app.get('/upload-ui', (req, res) => {
  res.type('html').send(`<!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Upload File</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
            Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
          line-height: 1.6;
          max-width: 1200px;
          margin: 2rem auto;
          padding: 0 1rem;
          background: #f5f5f5;
        }
        .container {
          background: white;
          padding: 2rem;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
          text-align: center;
          color: #333;
          margin-bottom: 2rem;
        }
        .upload-section {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 2rem;
        }
        .folder-tree {
          border: 1px solid #ddd;
          border-radius: 4px;
          padding: 1rem;
          max-height: 400px;
          overflow-y: auto;
          background: #fafafa;
        }
        .folder-tree h3 {
          margin-top: 0;
          color: #555;
        }
        .tree-item {
          padding: 0.25rem 0;
          cursor: pointer;
          user-select: none;
        }
        .tree-item:hover {
          background: #e3f2fd;
        }
        .tree-item.selected {
          background: #2196f3;
          color: white;
        }
        .tree-children {
          margin-left: 1.5rem;
        }
        .folder-icon::before {
          content: '📁 ';
        }
        .folder-icon.expanded::before {
          content: '📂 ';
        }
        .upload-controls {
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }
        #status {
          white-space: pre-wrap;
          background: #f5f5f5;
          padding: 1rem;
          border-radius: 4px;
          margin-top: 1rem;
          min-height: 50px;
        }
        input[type="file"] {
          display: block;
          margin-bottom: 0.5rem;
          padding: 0.5rem;
          border: 2px dashed #ddd;
          border-radius: 4px;
          width: 100%;
          background: white;
        }
        input[type="file"]:hover {
          border-color: #999;
        }
        button {
          background: #2196f3;
          color: white;
          border: none;
          padding: 0.75rem 1.5rem;
          border-radius: 4px;
          font-size: 1rem;
          cursor: pointer;
          transition: background 0.2s;
        }
        button:hover {
          background: #1976d2;
        }
        button:disabled {
          background: #ccc;
          cursor: not-allowed;
        }
        .selected-path {
          background: #e3f2fd;
          padding: 0.5rem;
          border-radius: 4px;
          margin-bottom: 0.5rem;
          font-weight: 500;
        }
        @media (max-width: 768px) {
          .upload-section {
            grid-template-columns: 1fr;
          }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>File Upload Manager</h1>
        <div class="upload-section">
          <div class="folder-tree">
            <h3>Select Target Folder</h3>
            <div id="treeContainer">Loading folder structure...</div>
          </div>
          <div class="upload-controls">
            <div class="selected-path">
              Selected: <span id="selectedPath">/Upload</span>
            </div>
            <input type="file" id="fileInput" multiple />
            <button id="uploadBtn">Upload Files</button>
            <div id="status">Ready to upload files...</div>
          </div>
        </div>
      </div>

      <script>
        (function() {
          let selectedPath = 'Upload';
          let directoryTree = [];
          
          const fileInput = document.getElementById('fileInput');
          const statusEl = document.getElementById('status');
          const selectedPathEl = document.getElementById('selectedPath');
          const treeContainer = document.getElementById('treeContainer');
          const uploadBtn = document.getElementById('uploadBtn');
          
          // Fetch directory tree on load
          async function loadDirectoryTree() {
            try {
              const response = await fetch('/api/directory-tree');
              const data = await response.json();
              directoryTree = data.tree;
              renderTree();
            } catch (err) {
              treeContainer.innerHTML = '<div style="color: red;">Failed to load directory structure</div>';
            }
          }
          
          // Render the directory tree
          function renderTree() {
            treeContainer.innerHTML = '';
            const rootEl = createTreeItem('/', '', true);
            rootEl.classList.add('selected');
            treeContainer.appendChild(rootEl);
            
            const childrenContainer = document.createElement('div');
            childrenContainer.className = 'tree-children';
            renderTreeItems(directoryTree, childrenContainer);
            treeContainer.appendChild(childrenContainer);
          }
          
          // Create a tree item element
          function createTreeItem(name, path, isRoot = false) {
            const item = document.createElement('div');
            item.className = 'tree-item';
            if (!isRoot) {
              item.innerHTML = '<span class="folder-icon">' + name + '</span>';
            } else {
              item.innerHTML = '<span class="folder-icon expanded">Root</span>';
            }
            
            item.addEventListener('click', function(e) {
              e.stopPropagation();
              
              // Update selection
              document.querySelectorAll('.tree-item').forEach(el => el.classList.remove('selected'));
              item.classList.add('selected');
              
              selectedPath = path || '';
              selectedPathEl.textContent = '/' + selectedPath;
              
              // Toggle expand/collapse for folders with children
              const icon = item.querySelector('.folder-icon');
              if (icon) {
                const isExpanded = icon.classList.toggle('expanded');
                const childrenContainer = item.nextElementSibling;
                if (childrenContainer && childrenContainer.classList.contains('tree-children')) {
                  childrenContainer.style.display = isExpanded ? 'block' : 'none';
                }
              }
            });
            
            return item;
          }
          
          // Recursively render tree items
          function renderTreeItems(items, container) {
            items.forEach(item => {
              if (item.type === 'directory') {
                const itemEl = createTreeItem(item.name, item.path);
                container.appendChild(itemEl);
                
                if (item.children && item.children.length > 0) {
                  const childrenContainer = document.createElement('div');
                  childrenContainer.className = 'tree-children';
                  childrenContainer.style.display = 'block';
                  renderTreeItems(item.children, childrenContainer);
                  container.appendChild(childrenContainer);
                }
              }
            });
          }
          
          // Upload handler
          uploadBtn.addEventListener('click', async () => {
            if (!fileInput.files.length) {
              alert('Please choose files to upload.');
              return;
            }
            
            uploadBtn.disabled = true;
            const files = Array.from(fileInput.files);
            statusEl.textContent = 'Uploading ' + files.length + ' file(s)...\\n';
            
            let successCount = 0;
            let failCount = 0;
            
            for (const file of files) {
              try {
                const targetPath = selectedPath ? selectedPath + '/' + file.name : file.name;
                const response = await fetch('/upload/' + encodeURIComponent(targetPath), {
                  method: 'PUT',
                  body: file,
                });
                
                if (response.ok) {
                  successCount++;
                  statusEl.textContent += '✅ ' + file.name + '\\n';
                } else {
                  failCount++;
                  const text = await response.text();
                  statusEl.textContent += '❌ ' + file.name + ' (error: ' + text + ')\\n';
                }
              } catch (err) {
                failCount++;
                statusEl.textContent += '❌ ' + file.name + ' (error: ' + err.message + ')\\n';
              }
            }
            
            statusEl.textContent += '\\nUpload complete: ' + successCount + ' succeeded, ' + failCount + ' failed';
            uploadBtn.disabled = false;
            
            // Clear file input
            fileInput.value = '';
            
            // Reload directory tree
            setTimeout(loadDirectoryTree, 1000);
          });
          
          // Load directory tree on page load
          loadDirectoryTree();
        })();
      </script>
    </body>
  </html>`);
});

// Add PUT endpoint for file uploads to /upload/:filename
app.put('/upload/:filename(*)', (req, res) => {
  // Parse the filename parameter which includes the path
  const fullPath = req.params.filename || req.params[0];
  
  // Prevent path traversal attacks
  const normalizedPath = path.normalize(fullPath).replace(/^(\.\.(\/|\\|$))+/, '');
  const targetPath = path.join(config.dir, normalizedPath);
  
  // Ensure the target path is within the configured directory
  if (!targetPath.startsWith(config.dir)) {
    return res.status(400).send('Invalid path');
  }
  
  // Ensure target directory exists
  const targetDir = path.dirname(targetPath);
  if (!fs.existsSync(targetDir)) {
    try {
      fs.mkdirSync(targetDir, { recursive: true });
    } catch (err) {
      console.error('Failed to create directory:', err);
      return res.status(500).send('Server error creating directory');
    }
  }

  const writeStream = fs.createWriteStream(targetPath);
  req.pipe(writeStream);

  writeStream.on('finish', () => {
    res.status(201).send('File uploaded successfully');
  });

  writeStream.on('error', (err) => {
    console.error('Error writing file:', err);
    res.status(500).send('Error uploading file');
  });
});

// Redirect root to upload UI
app.get('/', (req, res) => {
  res.redirect('/upload-ui');
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

