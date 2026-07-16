const WEB_ROOT = `${import.meta.dir}/build/web`;

// THRT runtime lives in the same container. Use same-origin proxy.
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8060';

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

const NO_CACHE_EXTS = new Set(['.js', '.mjs', '.wasm', '.data', '.mem']);

function headersForPath(path) {
  const h = { 'Content-Type': MIME[ext(path)] || 'application/octet-stream' };
  if (NO_CACHE_EXTS.has(ext(path)) || path.endsWith('/index.html')) {
    h['Cache-Control'] = 'no-store, max-age=0';
  }
  return h;
}

Bun.serve({
  port: 8040,
  async fetch(req) {
    const url = new URL(req.url);
    let path = url.pathname;

    // Proxy API + MCP calls to backend. In production, the frontend is
    // served from the same Bun proxy as the API (same-origin), so no
    // separate proxy is needed. The dev preview uses this Bun forward.
    if (path.startsWith('/api/') || path.startsWith('/mcp/')) {
      const target = `${BACKEND_URL}${path}${url.search}`;
      try {
        const init = {
          method: req.method,
          headers: req.headers,
          compress: false,
        };
        if (req.method !== 'GET' && req.method !== 'HEAD') {
          init.body = await req.text();
        }
        const upstream = await fetch(target, init);
        // Strip hop-by-hop / encoding headers so Bun doesn't double-compress
        // (which would invalidate the upstream Content-Length and break Caddy).
        const headers = new Headers();
        for (const [k, v] of upstream.headers) {
          const lk = k.toLowerCase();
          if (lk === 'content-encoding' || lk === 'content-length' || lk === 'transfer-encoding') {
            continue;
          }
          headers.set(k, v);
        }
        return new Response(upstream.body, {
          status: upstream.status,
          statusText: upstream.statusText,
          headers,
        });
      } catch (e) {
        return new Response(`dev proxy error: ${e}`, { status: 502 });
      }
    }

    if (path === '/') path = '/index.html';

    const file = Bun.file(`${WEB_ROOT}${path}`);
    if (await file.exists()) {
      return new Response(file, { headers: headersForPath(path) });
    }

    const index = Bun.file(`${WEB_ROOT}/index.html`);
    if (await index.exists()) {
      return new Response(index, { headers: headersForPath('/index.html') });
    }

    return new Response('Not Found', { status: 404 });
  },
});
