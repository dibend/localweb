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

app.use(express.static(config.dir), serveIndex(config.dir, { 'icons': true }));

// Add PUT endpoint for file uploads to /upload/:filename
app.put('/upload/:filename', (req, res) => {
  const uploadDir = path.join(config.dir, 'Upload');

  // Ensure Upload directory exists
  if (!fs.existsSync(uploadDir)) {
    try {
      fs.mkdirSync(uploadDir, { recursive: true });
    } catch (err) {
      console.error('Failed to create Upload directory:', err);
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

