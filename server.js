var express = require('express');
var serveIndex = require('serve-index');
var config = require('./config');

var app = express();

app.use(express.static(config.dir), serveIndex(config.dir, {'icons': true}));

app.listen(8080);
