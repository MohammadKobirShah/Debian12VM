#!/bin/bash

clear
echo "╔════════════════════════════════════════╗"
echo "║   🌐 Web Desktop - One-Click Deploy   ║"
echo "║         (No Password Required)         ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not installed!"
    echo "Install: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "🔍 Checking for existing container..."
if docker ps -a --format '{{.Names}}' | grep -q '^vnc-desktop$'; then
    echo "🗑️  Removing old container..."
    docker rm -f vnc-desktop
fi

echo ""
echo "📦 Building image (this may take 2-3 minutes)..."
docker build -t vnc-desktop:latest .

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "🚀 Starting container..."
docker run -d \
  --name vnc-desktop \
  -p 6080:6080 \
  -e VNC_RESOLUTION=1920x1080 \
  --shm-size=512m \
  --restart unless-stopped \
  vnc-desktop:latest

echo ""
echo "⏳ Waiting for desktop to start..."
sleep 8

if docker ps --format '{{.Names}}' | grep -q '^vnc-desktop$'; then
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║          ✅ DEPLOYMENT SUCCESS!        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "🌐 Open in browser:"
    echo "   👉 http://localhost:6080/vnc.html"
    echo ""
    echo "✅ No password needed - just click Connect!"
    echo ""
    echo "📊 Useful commands:"
    echo "   Logs:    docker logs -f vnc-desktop"
    echo "   Stop:    docker stop vnc-desktop"
    echo "   Restart: docker restart vnc-desktop"
    echo "   Remove:  docker rm -f vnc-desktop"
    echo ""
else
    echo "❌ Container failed to start!"
    echo "📋 Check logs: docker logs vnc-desktop"
    exit 1
fi
