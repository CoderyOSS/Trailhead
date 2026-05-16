FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai@latest

WORKDIR /workspace

COPY opencode.json.tmpl /etc/opencode/opencode.json.tmpl
COPY AGENTS.md /etc/opencode/AGENTS.md
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV OPENCODE_SERVER_PASSWORD=""
ENV PORT=8080

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
