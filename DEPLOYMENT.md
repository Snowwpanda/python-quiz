# Deployment Guide for Fly.io

This guide will help you deploy the full-stack application (backend + frontend) to Fly.io in a single container.

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

## Step 1: Deploy the Application

1. **Create the app** (from project root):
   ```bash
   flyctl apps create python-quiz
   ```

2. **Set environment variables** (secrets):
   ```bash
   flyctl secrets set CORS_ORIGINS="http://localhost:4321,https://python-quiz.fly.dev" -a python-quiz
   ```

3. **Deploy the application**:
   ```bash
   flyctl deploy -a python-quiz
   ```
   
   This will build and deploy both the backend and frontend in a single container.

4. **Get the app URL**:
   ```bash
   flyctl info -a python-quiz
   ```
   
   Your app will be available at `https://python-quiz.fly.dev`

5. **Test the deployment**:
   ```bash
   # Test frontend
   curl https://python-quiz.fly.dev
   
   # Test backend API
   curl https://python-quiz.fly.dev:8080
   # Or visit https://python-quiz.fly.dev:8080/docs in your browser
   ```

## Step 2: Test Your Deployment

1. Visit your app URL: `https://python-quiz.fly.dev`
2. Create a room as host
3. Join as participant (open in incognito/different browser)
4. Start a question and verify real-time updates work

## Updating Your Deployment

```bash
# After making changes to either backend or frontend code
flyctl deploy -a python-quiz
```

## Monitoring and Logs

### View Application Logs
```bash
flyctl logs -a python-quiz
```

### Check App Status
```bash
flyctl status -a python-quiz
```

### SSH into the Machine
```bash
flyctl ssh console -a python-quiz
```

## Scaling (if needed)

```bash
# Increase memory (app runs both frontend + backend)
flyctl scale memory 1024 -a python-quiz

# Scale to multiple instances
flyctl scale count 2 -a python-quiz
```

## Costs

Fly.io free tier includes:
- Up to 3 shared-cpu-1x 256mb VMs
- 160GB outbound data transfer

Note: Since we're running both backend and frontend in one container, we use 512MB RAM (configurable in fly.toml). This uses more resources than the free tier's 256MB, but keeps deployment simple.

## Troubleshooting

### Application Issues

**Check if app is running:**
```bash
flyctl status -a python-quiz
curl https://python-quiz.fly.dev
```

**View real-time logs:**
```bash
flyctl logs -a python-quiz
```

**Common issues:**
- **Both services running**: Check logs to ensure both backend (port 8080) and frontend (port 4321) started
- **Dependencies**: Check that `uv sync` and `npm install` ran successfully during build
- **Environment variables**: Verify CORS_ORIGINS is set correctly
- **Memory**: If app crashes, try increasing memory to 1024MB

### CORS Errors

If you see CORS errors in the browser console:

1. Verify CORS_ORIGINS is set:
   ```bash
   flyctl secrets list -a python-quiz
   ```

2. Update if needed:
   ```bash
   flyctl secrets set CORS_ORIGINS="http://localhost:4321,https://python-quiz.fly.dev" -a python-quiz
   ```

### WebSocket Issues

1. Since both services run in the same container, WebSocket uses localhost internally
2. Check browser console for WebSocket connection errors
3. Verify both services are running in the logs: `flyctl logs -a python-quiz`

## Clean Up

To delete the app and stop all charges:

```bash
flyctl apps destroy python-quiz
```

## Custom Domains (Optional)

If you want to use your own domain:

1. **Add domain**:
   ```bash
   flyctl certs add yourdomain.com -a python-quiz
   ```

2. **Update DNS**: Add CNAME record pointing to Fly.io

3. **Update CORS**:
   ```bash
   flyctl secrets set CORS_ORIGINS="http://localhost:4321,https://yourdomain.com" -a python-quiz
   ```

---

**Need help?** Check out [Fly.io docs](https://fly.io/docs/) or run `flyctl help`
