# File Upload and Tree Visualization Feature

## Overview

The application has been enhanced with the following features:

1. **Tree Visualization**: A visual directory tree structure of the share folder on the root path (`/`)
2. **File Upload UI**: Integrated file upload interface on the root path
3. **Restricted Upload Location**: Files can only be uploaded to the `/Uploads` directory within the share folder

## Features

### Root Page (`/`)

When you access the root path, you'll see:

1. **Left Panel - Directory Structure**:
   - Visual tree representation of all files and folders
   - Clickable links that open the original serveIndex directory browser
   - Directories are shown with a `/` suffix
   - Files and folders are sorted (directories first, then files alphabetically)

2. **Right Panel - Upload Interface**:
   - Simple drag-and-drop or click-to-browse file upload
   - Files are automatically uploaded to `/Uploads` directory only
   - Real-time upload status feedback
   - Page automatically refreshes after successful upload

### Security Features

- **Restricted Upload Path**: Files can ONLY be uploaded to the `Uploads` folder
- **Path Traversal Protection**: File names are sanitized to prevent directory traversal attacks
- **Basic Authentication**: All access requires username/password authentication

### Directory Structure Example

```
├── Documents/
│   ├── readme.txt
│   └── report.pdf
├── Images/
│   ├── photo1.jpg
│   └── photo2.png
├── Videos/
│   └── demo.mp4
└── Uploads/
    └── (uploaded files appear here)
```

## Configuration

The application uses `config.js` with the following structure:

```javascript
module.exports = {
  dir: '/path/to/share/folder',  // Base directory for sharing
  user: 'username',              // Basic auth username
  password: 'password'           // Basic auth password
};
```

## Usage

1. Navigate to `http://localhost:8080/` or `https://localhost:8443/`
2. Authenticate with the configured username and password
3. Browse the directory tree on the left
4. Upload files using the interface on the right
5. Click on any folder link to navigate using the original directory browser

## Technical Details

- **Upload Endpoint**: `PUT /upload/:filename`
- **Upload Directory**: `{config.dir}/Uploads`
- **Backward Compatibility**: The old `/upload-ui` endpoint redirects to the root page
- **Original UI**: Subdirectory navigation preserves the original serveIndex interface

## Notes

- The `Uploads` directory is automatically created if it doesn't exist
- File uploads show success/error messages with appropriate styling
- The page refreshes automatically 2 seconds after a successful upload to show the new file
- The tree view uses monospace font for proper alignment of the tree structure