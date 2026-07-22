const WEB_ROOT = `${import.meta.dir}/build/web`;
const MAIN_DART = Bun.file(`${WEB_ROOT}/main.dart.js`);

let BUILD_VERSION;

async function initBuildVersion() {
  try {
    const stat = await MAIN_DART.stat();
    BUILD_VERSION = Math.floor(stat.mtimeMs).toString(36);
  } catch {
    BUILD_VERSION = Date.now().toString(36);
  }
}
await initBuildVersion();

// Carta runtime lives in the same container. Use same-origin proxy.
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

function headersForPath(path) {
  const h = { 'Content-Type': MIME[ext(path)] || 'application/octet-stream' };
  h['Cache-Control'] = 'no-store, max-age=0';
  return h;
}

async function indexResponse() {
  const indexFile = Bun.file(`${WEB_ROOT}/index.html`);
  if (!(await indexFile.exists())) return null;
  let html = await indexFile.text();
  html = html.replace(/(src|href)="([^"]+\.(?:js|css|json|png|svg|ico|wasm))"/g,
    (_, attr, src) => `${attr}="${src}?v=${BUILD_VERSION}"`);
  return new Response(html, { headers: headersForPath('/index.html') });
}

Bun.serve({
  port: 8040,
  async fetch(req, server) {
    const url = new URL(req.url);
    let path = url.pathname;

    // WebSocket upgrade for log stream. Bridges client <-> backend WS so the
    // frontend keeps same-origin connectivity through this proxy.
    if (
      (path.startsWith('/api/') || path.startsWith('/mcp/')) &&
      req.headers.get('upgrade')?.toLowerCase() === 'websocket'
    ) {
      const wsUrl = BACKEND_URL.replace(/^http/, 'ws') + path + url.search;
      if (server.upgrade(req, { data: { wsUrl } })) {
        return;
      }
      return new Response('WebSocket upgrade failed', { status: 400 });
    }

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
        // Always set Content-Type on error responses lacking one — browsers
        // may fire XHR onError instead of onLoad for 4xx/5xx without framing.
        const headers = new Headers();
        for (const [k, v] of upstream.headers) {
          const lk = k.toLowerCase();
          if (lk === 'content-encoding' || lk === 'content-length' || lk === 'transfer-encoding') {
            continue;
          }
          headers.set(k, v);
        }
        if (upstream.status >= 400 && !headers.has('content-type')) {
          headers.set('content-type', 'text/plain; charset=utf-8');
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

    if (path === '/' || path === '/index.html') {
      const idx = await indexResponse();
      if (idx) return idx;
      return new Response('Not Found', { status: 404 });
    }

    // Bust Flutter's internal main.dart.js reference in the bootstrap
    if (path.endsWith('/flutter_bootstrap.js')) {
      const file = Bun.file(`${WEB_ROOT}${path}`);
      if (await file.exists()) {
        let js = await file.text();
        js = js.replace(/"(main\.dart\.js)"/g, '"$1?v=' + BUILD_VERSION + '"');
        return new Response(js, { headers: headersForPath(path) });
      }
    }

    const file = Bun.file(`${WEB_ROOT}${path}`);
    if (await file.exists()) {
      return new Response(file, { headers: headersForPath(path) });
    }

    const idx = await indexResponse();
    if (idx) return idx;

    return new Response('Not Found', { status: 404 });
  },

  // WebSocket bridge: on open, connect to the backend WS URL captured during
  // upgrade; pipe frames both directions; close both sides on either end's
  // close event.
  websocket: {
    open(ws) {
      const { wsUrl } = ws.data;
      const upstream = new WebSocket(wsUrl);
      ws.data.upstream = upstream;
      ws.data.pending = [];

      upstream.addEventListener('open', () => {
        for (const msg of ws.data.pending) upstream.send(msg);
        ws.data.pending = [];
      });
      upstream.addEventListener('message', (ev) => {
        try {
          ws.send(ev.data);
        } catch (_) {
          // Client already gone — upstream close will follow.
        }
      });
      upstream.addEventListener('close', (ev) => {
        try {
          ws.close(ev.code, ev.reason);
        } catch (_) {}
      });
      upstream.addEventListener('error', () => {
        try {
          ws.close(1011, 'upstream error');
        } catch (_) {}
      });
    },
    message(ws, message) {
      const upstream = ws.data.upstream;
      if (upstream && upstream.readyState === WebSocket.OPEN) {
        upstream.send(message);
      } else {
        ws.data.pending.push(message);
      }
    },
    close(ws, code, reason) {
      const upstream = ws.data.upstream;
      if (upstream && upstream.readyState !== WebSocket.CLOSED) {
        try {
          upstream.close(code, reason);
        } catch (_) {}
      }
    },
  },
});
