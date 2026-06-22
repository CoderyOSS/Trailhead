const WEB_ROOT = `${import.meta.dir}/build/web`;

// Backend URL for dev-preview API proxying. Defaults to Docker bridge host
// (apps container -> host trailhead service). Override via env:
//   BACKEND_URL=http://localhost:4050 bun run serve.js
const BACKEND_URL = process.env.BACKEND_URL || 'http://host.docker.internal:4050';

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.css': 'text/css',
  '.map': 'application/json',
};

function ext(path) {
  const dot = path.lastIndexOf('.');
  return dot >= 0 ? path.slice(dot) : '';
}

Bun.serve({
  port: 8040,
  async fetch(req) {
    const url = new URL(req.url);
    let path = url.pathname;

    // Proxy API + MCP calls to backend. In production, the frontend is
    // served from the same Rust binary as the API (same-origin), so no
    // proxy is needed. The dev preview uses this Bun forward.
    if (path.startsWith('/api/') || path.startsWith('/mcp/')) {
      const target = `${BACKEND_URL}${path}${url.search}`;
      try {
        const init = {
          method: req.method,
          headers: req.headers,
        };
        if (req.method !== 'GET' && req.method !== 'HEAD') {
          init.body = await req.text();
        }
        return await fetch(target, init);
      } catch (e) {
        return new Response(`dev proxy error: ${e}`, { status: 502 });
      }
    }

    if (path === '/') path = '/index.html';

    const file = Bun.file(`${WEB_ROOT}${path}`);
    if (await file.exists()) {
      return new Response(file, {
        headers: { 'Content-Type': MIME[ext(path)] || 'application/octet-stream' },
      });
    }

    const index = Bun.file(`${WEB_ROOT}/index.html`);
    if (await index.exists()) {
      return new Response(index, {
        headers: { 'Content-Type': MIME['.html'] },
      });
    }

    return new Response('Not Found', { status: 404 });
  },
});
