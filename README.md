# Local Web
Serves directory over HTTP & HTTPS with file upload and tree visualization

Serves directory over HTTP & HTTPS on Ubuntu Server LTS with an integrated file upload interface and visual directory tree structure.

## Features

- 📁 **Visual Directory Tree**: Interactive tree view of your share folder on the root path
- 📤 **Integrated Upload UI**: File upload interface directly on the main page
- 🔒 **Secure Uploads**: Files can only be uploaded to the designated `/Uploads` directory
- 🔐 **Basic Authentication**: Password-protected access to all resources
- 📂 **Classic Directory Browser**: Original serveIndex UI preserved for subdirectory navigation

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

> **Note:** The server will automatically create an `/Uploads` subdirectory within your configured `dir` if it doesn't exist.

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

## User Interface

### Root Path (`/`)

When you access the root URL, you'll see a split-screen interface:

1. **Left Panel - Directory Tree**
   - Visual ASCII-art tree structure of all files and folders
   - Clickable links for navigation
   - Directories shown with `/` suffix
   - Smart sorting (directories first, then files alphabetically)

2. **Right Panel - Upload Interface**
   - Drag-and-drop or click-to-browse file selection
   - Files automatically upload to `/Uploads` directory
   - Real-time upload progress and status
   - Page auto-refreshes after successful upload

### Subdirectory Navigation

Clicking any folder link in the tree opens the original serveIndex directory browser, maintaining the classic file browsing experience.

---

## REST API

| Method | Endpoint                | Description                               | Auth required |
|--------|-------------------------|-------------------------------------------|---------------|
| GET    | `/`                     | New: Tree view + upload UI                | ✅            |
| GET    | `/[path]`               | Serves files & classic directory listing  | ✅            |
| PUT    | `/upload/:filename`     | Uploads a file to `<dir>/Uploads/`        | ✅            |
| GET    | `/upload-ui`            | Redirects to root path `/`                | ✅            |

### `PUT /upload/:filename`

* **Body:** raw bytes of the file (any content-type)
* **Target Directory:** Files are saved to `<config.dir>/Uploads/` (changed from `/Upload/`)
* **Security:** Path traversal protection ensures files can only be saved in the Uploads directory
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

### Root Path UI (`GET /`)

The enhanced root interface provides:
- **Tree Visualization**: Complete directory structure with clickable navigation
- **Upload Form**: Browser-based file upload without command-line tools
- **Responsive Design**: Works on desktop and mobile devices

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
├── server.js            # Main application with enhanced root UI
├── start.sh             # Helper script (optional)
├── ssl/                 # SSL certificates
├── config.js            # Your personal configuration (not committed)
├── __tests__/           # Jest test suite
├── UPLOAD_FEATURE_README.md  # Detailed upload feature documentation
└── README.md            # You're reading it
```

## Example Directory Structure

After configuration, your share directory might look like:

```
/home/share/
├── Documents/
│   ├── report.pdf
│   └── notes.txt
├── Images/
│   ├── photo1.jpg
│   └── photo2.png
├── Videos/
│   └── demo.mp4
└── Uploads/           # Auto-created, all uploads go here
    └── uploaded-file.zip
```

---

## Contributing

Issues and PRs are welcome! Please provide a clear description, follow the code style in the project, and include tests for any new features.
