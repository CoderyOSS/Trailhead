const WEB_ROOT = `${import.meta.dir}/build/web`;

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
