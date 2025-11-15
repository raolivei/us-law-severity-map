FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies for native modules (mapbox-gl, etc.)
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    libc6-compat

# Update npm to latest version
RUN npm install -g npm@latest

# Copy package files
COPY webapp/package.json ./
COPY webapp/package-lock.json* ./

# Install dependencies - use npm install directly with legacy-peer-deps
# This handles React 19 + Next.js 16 compatibility issues
# If lockfile causes issues, remove it and reinstall
RUN npm install --legacy-peer-deps || \
    (rm -f package-lock.json && npm install --legacy-peer-deps)

# Copy source code and config files
COPY webapp/ .

# Ensure all config files are present
RUN ls -la && \
    echo "=== Checking config files ===" && \
    [ -f next.config.ts ] && echo "✓ next.config.ts" || echo "✗ next.config.ts missing" && \
    [ -f tsconfig.json ] && echo "✓ tsconfig.json" || echo "✗ tsconfig.json missing" && \
    [ -f postcss.config.mjs ] && echo "✓ postcss.config.mjs" || echo "✗ postcss.config.mjs missing" && \
    [ -f package.json ] && echo "✓ package.json" || echo "✗ package.json missing"

# Set build environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Build the Next.js application with increased memory limit and verbose output
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build 2>&1 | tee /tmp/build.log || (cat /tmp/build.log && exit 1)

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy built application
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/next.config.ts ./

# Use non-root user for security
RUN chown -R 1000:1000 /app 2>/dev/null || \
    (adduser -D -u 1001 appuser && chown -R appuser:appuser /app) || \
    chown -R node:node /app || true
USER 1000

# Expose port
EXPOSE 3000

# Health check (using node to make HTTP request)
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Start the application
CMD ["npm", "start"]

