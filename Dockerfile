FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY webapp/package*.json ./
RUN npm install --legacy-peer-deps

# Copy source code
COPY webapp/ .

# Build the Next.js application
RUN npm run build

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

