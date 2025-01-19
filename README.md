# Local Web
Serves directory over HTTP & HTTPS

Serves directory over HTTP & HTTPS on Ubuntu Server LTS

## Installation

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

1. Create a file named `config.json` with the following content:
```json
{
  "dir": "/home/share",
  "user": "your_username",
  "password": "<your_password_here>"
}
```
2. Start the server:
```bash
node server.js
```

To access your files using HTTP Basic Auth, open a web browser and navigate to `http://your_server_ip:port` (replace with the actual IP address and port number of your server). You will be prompted to enter a username and password. Enter `your_username` as the username and `<your_password_here>` as the password.

Note: Make sure to replace `your_username` and `<your_password_here>` with your actual desired credentials.
node server.js
```
To access your files using HTTP Basic Auth, open a web browser and navigate to `http://your_server_ip:port` (replace with the actual IP address and port number of      
your server). You will be prompted to enter a username and password. Enter `your_username` as the username and `<your_password_here>` as the password.

Note: Make sure to replace `your_username` and `<your_password_here>` with your actual desired credentials.```
