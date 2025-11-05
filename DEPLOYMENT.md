# Deployment Guide for Fly.io

This guide will help you deploy both the backend and frontend to Fly.io.

## Prerequisites

1. **Install flyctl** (Fly.io CLI):
   ```bash
   # macOS/Linux
   curl -L https://fly.io/install.sh | sh
   
   # Windows
   iwr https://fly.io/install.ps1 -useb | iex
   ```

2. **Sign up and login**:
   ```bash
   flyctl auth signup  # or flyctl auth login if you have an account
   ```

## Step 1: Deploy the Backend

1. **Create the backend app** (from project root):
   ```bash
   flyctl apps create python-quiz-backend
   ```

2. **Set environment variables** (secrets):
   ```bash
   flyctl secrets set CORS_ORIGINS="https://python-quiz-frontend.fly.dev" -a python-quiz-backend
   ```
   
   Note: We'll update this after deploying the frontend if the URL is different.

3. **Deploy the backend**:
   ```bash
   flyctl deploy -c fly.toml -a python-quiz-backend
   ```

4. **Get the backend URL**:
   ```bash
   flyctl info -a python-quiz-backend
   ```
   
   Save this URL - you'll need it for the frontend (e.g., `https://python-quiz-backend.fly.dev`)

5. **Test the backend**:
   ```bash
   curl https://python-quiz-backend.fly.dev
   # Or visit https://python-quiz-backend.fly.dev/docs in your browser
   ```

## Step 2: Deploy the Frontend

1. **Create the frontend app**:
   ```bash
   flyctl apps create python-quiz-frontend
   ```

2. **Set build-time environment variables**:
   
   Replace `YOUR-BACKEND-URL` with the URL from Step 1:
   ```bash
   flyctl deploy -c fly.frontend.toml \
     --build-arg PUBLIC_BACKEND_API=https://YOUR-BACKEND-URL.fly.dev \
     --build-arg PUBLIC_BACKEND_WS=wss://YOUR-BACKEND-URL.fly.dev \
     -a python-quiz-frontend
   ```
   
   Example:
   ```bash
   flyctl deploy -c fly.frontend.toml \
     --build-arg PUBLIC_BACKEND_API=https://python-quiz-backend.fly.dev \
     --build-arg PUBLIC_BACKEND_WS=wss://python-quiz-backend.fly.dev \
     -a python-quiz-frontend
   ```

3. **Get the frontend URL**:
   ```bash
   flyctl info -a python-quiz-frontend
   ```

## Step 3: Update Backend CORS

Now that you have the frontend URL, update the backend CORS settings:

```bash
flyctl secrets set CORS_ORIGINS="https://python-quiz-frontend.fly.dev,http://localhost:4321" -a python-quiz-backend
```

This will automatically trigger a redeployment of the backend.

## Step 4: Test Your Deployment

1. Visit your frontend URL: `https://python-quiz-frontend.fly.dev`
2. Create a room as host
3. Join as participant (open in incognito/different browser)
4. Start a question and verify real-time updates work

## Updating Your Deployment

### Update Backend

```bash
# After making changes to backend code
flyctl deploy -c fly.toml -a python-quiz-backend
```

### Update Frontend

```bash
# After making changes to frontend code
flyctl deploy -c fly.frontend.toml \
  --build-arg PUBLIC_BACKEND_API=https://python-quiz-backend.fly.dev \
  --build-arg PUBLIC_BACKEND_WS=wss://python-quiz-backend.fly.dev \
  -a python-quiz-frontend
```

## Monitoring and Logs

### View Backend Logs
```bash
flyctl logs -a python-quiz-backend
```

### View Frontend Logs
```bash
flyctl logs -a python-quiz-frontend
```

### Check App Status
```bash
flyctl status -a python-quiz-backend
flyctl status -a python-quiz-frontend
```

### SSH into a Machine
```bash
flyctl ssh console -a python-quiz-backend
flyctl ssh console -a python-quiz-frontend
```

## Scaling (if needed)

### Scale Backend
```bash
# Increase memory
flyctl scale memory 512 -a python-quiz-backend

# Scale to multiple instances
flyctl scale count 2 -a python-quiz-backend
```

### Scale Frontend
```bash
# Increase memory
flyctl scale memory 512 -a python-quiz-frontend

# Scale to multiple instances
flyctl scale count 2 -a python-quiz-frontend
```

## Costs

Fly.io free tier includes:
- Up to 3 shared-cpu-1x 256mb VMs
- 160GB outbound data transfer

This should be sufficient for development and small-scale use. Both apps (backend + frontend) will fit within the free tier.

## Troubleshooting

### Backend Issues

**Check if backend is running:**
```bash
flyctl status -a python-quiz-backend
curl https://python-quiz-backend.fly.dev
```

**View real-time logs:**
```bash
flyctl logs -a python-quiz-backend
```

**Common issues:**
- **Port mismatch**: Ensure Dockerfile exposes 8080 and uvicorn listens on 8080
- **Dependencies**: Check that `uv sync` ran successfully during build
- **Environment variables**: Verify CORS_ORIGINS is set correctly

### Frontend Issues

**Check if frontend is running:**
```bash
flyctl status -a python-quiz-frontend
curl https://python-quiz-frontend.fly.dev
```

**View real-time logs:**
```bash
flyctl logs -a python-quiz-frontend
```

**Common issues:**
- **Build arguments**: Ensure PUBLIC_BACKEND_API and PUBLIC_BACKEND_WS were passed during deployment
- **Node version**: Dockerfile uses Node 20 - ensure compatibility
- **WebSocket connection**: Must use `wss://` (not `ws://`) in production

### CORS Errors

If you see CORS errors in the browser console:

1. Verify backend CORS_ORIGINS includes your frontend URL:
   ```bash
   flyctl secrets list -a python-quiz-backend
   ```

2. Update if needed:
   ```bash
   flyctl secrets set CORS_ORIGINS="https://python-quiz-frontend.fly.dev,http://localhost:4321" -a python-quiz-backend
   ```

### WebSocket Issues

1. Ensure you're using `wss://` (not `ws://`) for the backend WebSocket URL
2. Check browser console for WebSocket connection errors
3. Verify backend is running: `flyctl status -a python-quiz-backend`

## Clean Up

To delete the apps and stop all charges:

```bash
flyctl apps destroy python-quiz-backend
flyctl apps destroy python-quiz-frontend
```

## Custom Domains (Optional)

If you want to use your own domain:

1. **Add domain to backend**:
   ```bash
   flyctl certs add yourdomain.com -a python-quiz-backend
   ```

2. **Add domain to frontend**:
   ```bash
   flyctl certs add app.yourdomain.com -a python-quiz-frontend
   ```

3. **Update DNS**: Add CNAME records pointing to Fly.io
4. **Update CORS**: Update backend CORS_ORIGINS to include your custom domain

---

**Need help?** Check out [Fly.io docs](https://fly.io/docs/) or run `flyctl help`
