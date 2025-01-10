#!/bin/bash

# Redirect port 80 (http) to 8080 (http server)
# Allows express server to be run as regular user for security measures


nohup node server.js &> localweb.log &
