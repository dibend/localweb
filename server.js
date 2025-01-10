var express = require('express');
var serveIndex = require('serve-index');
var morgan = require('morgan');
var fs = require('fs');
var http = require('http');
var https = require('https');
var compression = require('compression');
var auth = require('basic-auth');
var config = require('./config');

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

console.log('"ip","date","method","url","status","time"');

var sslKey = fs.readFileSync('ssl/localweb.key', 'utf8');
var sslCert = fs.readFileSync('ssl/localweb.crt', 'utf8');

var creds = {
  key: sslKey,
  cert: sslCert,
};

http.createServer(app).listen(8080);
https.createServer(creds, app).listen(8443);

