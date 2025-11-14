#!/bin/bash
set -e

IMAGE_NAME="us-law-severity-map-web"
IMAGE_TAG="test"
CONTAINER_NAME="us-law-severity-map-test"
DEFAULT_PORT=3000

# Function to check if a port is in use
port_in_use() {
    local port=$1
    lsof -Pi :${port} -sTCP:LISTEN -t >/dev/null 2>&1
}

# Function to find an available port starting from the default
find_available_port() {
    local port=$1
    local max_port=$((port + 10))
    
    while [ $port -le $max_port ]; do
        if ! port_in_use $port; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo ""
    return 1
}

# Check for port conflicts and find available port
# Allow PORT to be overridden via environment variable
PORT=${PORT:-$DEFAULT_PORT}
if port_in_use $PORT; then
    echo "⚠️  Port ${PORT} is already in use"
    echo "🔍 Checking what's using port ${PORT}..."
    lsof -Pi :${PORT} -sTCP:LISTEN || true
    echo ""
    echo "🔍 Looking for an available port..."
    AVAILABLE_PORT=$(find_available_port $PORT)
    
    if [ -z "$AVAILABLE_PORT" ]; then
        echo "❌ Could not find an available port between ${PORT} and $((PORT + 10))"
        echo "   Please stop the process using port ${PORT} or specify a different port:"
        echo "   PORT=<port> $0"
        exit 1
    fi
    
    PORT=$AVAILABLE_PORT
    echo "✅ Found available port: ${PORT}"
    echo ""
fi

echo "🔨 Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f Dockerfile .

echo "🧹 Cleaning up any existing test container..."
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

echo "🚀 Starting container on port ${PORT}..."
docker run -d -p ${PORT}:3000 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${IMAGE_TAG}

echo "⏳ Waiting for container to start..."
sleep 5

echo "🏥 Testing health endpoint..."
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -f -s http://localhost:${PORT} > /dev/null 2>&1; then
    echo "✅ Health check passed!"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "   Retry ${RETRY_COUNT}/${MAX_RETRIES}..."
  sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ Health check failed after ${MAX_RETRIES} retries"
  echo "📋 Container logs:"
  docker logs ${CONTAINER_NAME}
  docker stop ${CONTAINER_NAME} && docker rm ${CONTAINER_NAME}
  exit 1
fi

echo ""
echo "✅ Container is running successfully!"
echo "🌐 Access the app at: http://localhost:${PORT}"
echo ""
echo "To stop the container:"
echo "  docker stop ${CONTAINER_NAME} && docker rm ${CONTAINER_NAME}"
echo ""
echo "To view logs:"
echo "  docker logs -f ${CONTAINER_NAME}"

