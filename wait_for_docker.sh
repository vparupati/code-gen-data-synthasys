#!/bin/bash
# ============================================================================
# Wait for Docker to be Ready
# ============================================================================

echo "Waiting for Docker Desktop to start..."
echo ""

MAX_WAIT=120  # Maximum wait time in seconds
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if docker info > /dev/null 2>&1; then
        echo "✓ Docker is now running!"
        echo ""
        docker info | head -5
        echo ""
        echo "You can now run: docker-compose up -d"
        exit 0
    fi
    
    # Show progress every 10 seconds
    if [ $((ELAPSED % 10)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s / ${MAX_WAIT}s)"
        echo "  Make sure Docker Desktop is starting (check menu bar for whale icon)"
    fi
    
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

echo ""
echo "✗ Docker did not start within ${MAX_WAIT} seconds"
echo ""
echo "Please:"
echo "  1. Check if Docker Desktop is installed"
echo "  2. Manually open Docker Desktop from Applications"
echo "  3. Wait for the whale icon in menu bar to be steady"
echo "  4. Then run: docker info"
echo ""
exit 1

