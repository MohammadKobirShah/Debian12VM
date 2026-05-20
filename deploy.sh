#!/bin/bash

echo "🚀 VNC Desktop - One-Click Deploy"
echo "=================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "⚠️  Docker Compose not found. Using docker build/run..."
    
    echo "📦 Building image..."
    docker build -t vnc-desktop:latest .
    
    echo "🏃 Starting container..."
    docker run -d \
      --name vnc-desktop \
      -p 6080:6080 \
      -e VNC_RESOLUTION=1920x1080 \
      -e VNC_PASSWORD=changeme \
      --shm-size=512m \
      --restart unless-stopped \
      vnc-desktop:latest
else
    echo "📦 Building and starting with Docker Compose..."
    docker-compose up -d --build
fi

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📱 Access your desktop:"
echo "   🌐 Browser (noVNC): https://localhost:6080/vnc.html"
echo "   🖥️  VNC Client:      localhost:5901"
echo "   🔑 Password:        changeme"
echo ""
echo "📊 View logs:    docker logs -f vnc-desktop"
echo "🛑 Stop:         docker stop vnc-desktop"
echo "🗑️  Remove:       docker rm -f vnc-desktop"
echo ""
