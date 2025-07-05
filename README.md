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

Create a configuration file named `config.js` (preferred) **or** `config.json` in the project root with the following structure:

```js
// config.js (recommended – allows comments)
module.exports = {
  // Absolute path to the directory you want to share
  dir: "/home/share",

  // HTTP Basic-Auth credentials
  user: "your_username",
  password: "your_password",
};
```

If you prefer JSON, use the same keys **without** comments:

```json
{
  "dir": "/home/share",
  "user": "your_username",
  "password": "your_password"
}
```

> **Tip:** A sample file is available at `config.sample.json`.

### Starting the server

```bash
node server.js
# or, for live-reload during development
yarn nodemon server.js
```

The application starts two listeners by default:

* **HTTP**  `http://<host>:8080`
* **HTTPS** `https://<host>:8443` (requires `ssl/localweb.key` and `ssl/localweb.crt`)

When you access either URL you will be prompted for the username and password defined in `config.js`.

---

## REST API

| Method | Endpoint                | Description                             | Auth required |
|--------|-------------------------|-----------------------------------------|---------------|
| GET    | `/` / any file path     | Serves static files & directory listing | ✅            |
| PUT    | `/upload/:filename`     | Uploads a file into `<dir>/Upload/`     | ✅            |
| GET    | `/upload-ui`            | Simple HTML form for manual uploading   | ✅            |

### `PUT /upload/:filename`

* **Body:** raw bytes of the file (any content-type)
* **Success Response:** `201 Created` + `File uploaded successfully`
* **Failure Responses:**
  * `401 Unauthorized` when credentials are missing/invalid
  * `500 Internal Server Error` if the server cannot write the file

Example using `curl`:

```bash
curl -u "<user>:<pass>" \
     --upload-file ./picture.jpg \
     "http://localhost:8080/upload/picture.jpg"
```

### `GET /upload-ui`

Opens a minimal web interface to select a local file and upload it to the server without using the command-line. The page performs a `PUT /upload/:filename` request in the background.

---

## Running tests

Unit tests are written with **Jest** and **SuperTest**.

```bash
# install dependencies (including devDependencies)
npm install

# run the test suite
npm test
```

Tests spin up the Express application in-memory (no ports are bound) and verify:

1. Authentication is enforced.
2. Directory listing is served for authorised users.
3. File uploads succeed and are persisted to a temporary directory.

---

## File structure

```
├── server.js            # Main application entry point
├── start.sh             # Helper script (optional)
├── ssl/                 # SSL certificates
├── config.js            # Your personal configuration (not committed)
├── __tests__/           # Jest test suite
└── README.md            # You're reading it
```

---

## Contributing

Issues and PRs are welcome! Please provide a clear description, follow the code style in the project, and include tests for any new features.
