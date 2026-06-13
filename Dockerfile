# syntax=docker/dockerfile:1.6

# Library version pulled from the npm registry. Bump and rebuild to pick up new releases.
ARG LIB_VERSION=^0.2.0

# ─── Stage 1: build ────────────────────────────────────────────────────────────
FROM node:22-alpine AS build
ARG LIB_VERSION
WORKDIR /app

# Manifests first so the install layer caches independently of source changes.
COPY package.json package-lock.json ./

# Rewrite the dev-only file: dep to the published version, then install everything
# (including devDeps for the TypeScript compiler).
RUN npm pkg set "dependencies.single-player-sync=${LIB_VERSION}" \
 && rm -f package-lock.json \
 && npm install --no-audit --no-fund

# Sources
COPY tsconfig.json ./
COPY src ./src

# Compile TS → JS into dist/
RUN npm run build

# ─── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM node:22-alpine
ARG LIB_VERSION
WORKDIR /app

# Production deps only — no TypeScript compiler, no tsx, no dev tooling.
COPY package.json package-lock.json ./
RUN npm pkg set "dependencies.single-player-sync=${LIB_VERSION}" \
 && rm -f package-lock.json \
 && npm install --omit=dev --no-audit --no-fund \
 && npm cache clean --force

# Built JS and schemas
COPY --from=build /app/dist ./dist
COPY data/schemas ./data/schemas

ENV NODE_ENV=production \
    PORT=9000 \
    USER_DATA_DIR=/data/users \
    SCHEMAS_DIR=/app/data/schemas

EXPOSE 9000

# Intrinsic healthcheck — also overridable from compose. BusyBox wget ships in Alpine.
HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=10s \
  CMD wget -qO- http://localhost:9000/health || exit 1

CMD ["node", "dist/serve.js"]
