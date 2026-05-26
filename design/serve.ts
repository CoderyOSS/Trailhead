export default {
  port: 8020,
  async fetch(req: Request) {
    const url = new URL(req.url);
    let path = url.pathname === "/" ? "/Flutter Handoff.html" : url.pathname;
    const file = Bun.file("." + path);
    if (await file.exists()) {
      return new Response(file);
    }
    return new Response("Not Found", { status: 404 });
  },
};
