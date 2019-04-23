# Local Web
Serves directory over HTTP & HTTPS

## Debian Install

Install node.js if you haven't

`curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -`<br>
`sudo apt-get install -y nodejs`

Clone this repo

`git clone https://github.com/dibend/localweb.git`

Install dependencies

`cd localweb`<br>
`npm install`

Set folder to share in config.json

`{ "dir": "/home/share" }`

Create a folder named ssl and add ssl key and cert named localweb.key and localweb.crt

`mkdir ssl`<br>
`sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl/localweb.key -out ssl/localweb.crt`

run `./start.sh` to start server
