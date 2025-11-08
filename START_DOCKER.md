# How to Start Docker Desktop

## The Issue
You're seeing this error:
```
Cannot connect to the Docker daemon at unix:///Users/vparupati/.docker/run/docker.sock. 
Is the docker daemon running?
```

This means **Docker Desktop is not running**.

## Solution: Start Docker Desktop

### Method 1: From Applications
1. Open **Finder**
2. Go to **Applications**
3. Find **Docker** (or **Docker Desktop**)
4. Double-click to launch it
5. Wait for Docker to start (you'll see a whale icon in the menu bar)
6. The whale icon should be steady (not animated) when ready

### Method 2: From Spotlight
1. Press `Cmd + Space` to open Spotlight
2. Type "Docker" or "Docker Desktop"
3. Press Enter
4. Wait for Docker to start

### Method 3: From Terminal
```bash
open -a Docker
```

## Verify Docker is Running

After starting Docker Desktop, wait 30-60 seconds, then verify:

```bash
# Check if Docker is running
docker info

# You should see Docker system information, not an error
```

If you see Docker system info, you're ready! If you still see the error, wait a bit longer.

## Check Docker Desktop Status

Look at the menu bar (top right of your screen):
- **Whale icon animated** = Docker is starting up (wait)
- **Whale icon steady** = Docker is running ✓
- **No whale icon** = Docker is not running

## Once Docker is Running

Then you can start the databases:

```bash
# Start the databases
docker-compose up -d

# Check status
docker-compose ps

# View logs if needed
docker-compose logs postgres
docker-compose logs mongodb
```

## Troubleshooting

### Docker Desktop won't start
- Make sure you have enough disk space
- Check if Docker Desktop is already running (look for whale icon)
- Try restarting your Mac
- Reinstall Docker Desktop if needed

### Docker Desktop keeps stopping
- Check Docker Desktop settings
- Make sure it's set to start automatically (optional)
- Check system resources (RAM, CPU)

### Still having issues?
Run the diagnostic script:
```bash
./diagnose.sh
```

