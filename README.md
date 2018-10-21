# Local Web
Serves directory over HTTP

## Debian Install

Install node.js if you haven't

`curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -`
`sudo apt-get install -y nodejs`

Clone this repo

`git clone https://github.com/dibend/localweb.git`

Install dependencies

`cd localweb`
`npm install`

Set folder to share in config.json

`{ "dir": "/home/share" }`

Create a folder named ssl and add ssl key and cert named localweb.key and localweb.crt

run `./start.sh` to start server
