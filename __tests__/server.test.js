const request = require('supertest');
const fs = require('fs');
const path = require('path');
const os = require('os');

// ---- Mock configuration BEFORE importing the server ----
jest.mock('../config', () => {
  const fs = require('fs');
  const path = require('path');
  const os = require('os');

  const tmpDir = path.join(os.tmpdir(), `localweb-test-${Date.now()}`);
  fs.mkdirSync(tmpDir, { recursive: true });

  return {
    dir: tmpDir,
    user: 'testuser',
    password: 'testpass',
  };
}, { virtual: true });

// Now import the Express app (after mocking)
const app = require('../server');

// Helper to generate the Basic Auth header
function basicAuth(user, pass) {
  const token = Buffer.from(`${user}:${pass}`).toString('base64');
  return `Basic ${token}`;
}

describe('LocalWeb server', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(401);
  });

  it('allows authenticated directory listing', async () => {
    const res = await request(app)
      .get('/')
      .set('Authorization', basicAuth('testuser', 'testpass'));
    // 200 OK and HTML content of directory listing
    expect(res.statusCode).toBe(200);
    expect(res.text.toLowerCase()).toContain('<title');
  });

  it('uploads a file successfully', async () => {
    const testFileName = 'hello.txt';
    const testFileContent = 'Hello, LocalWeb!';

    const res = await request(app)
      .put(`/upload/${testFileName}`)
      .set('Authorization', basicAuth('testuser', 'testpass'))
      .send(testFileContent);

    expect(res.statusCode).toBe(201);
    expect(res.text).toBe('File uploaded successfully');

    const uploadDir = path.join(require('../config').dir, 'Upload');
    const uploadedPath = path.join(uploadDir, testFileName);
    expect(fs.existsSync(uploadedPath)).toBe(true);
    const saved = fs.readFileSync(uploadedPath, 'utf8');
    expect(saved).toBe(testFileContent);
  });

  it('serves the upload UI page', async () => {
    const res = await request(app)
      .get('/upload-ui')
      .set('Authorization', basicAuth('testuser', 'testpass'));

    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('<title>Upload File');
  });
});