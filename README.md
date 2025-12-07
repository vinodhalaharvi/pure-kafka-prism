# TCP Bridge

Generic TCP-over-WebSocket bridge. Enables browsers to connect to any TCP service (Kafka, Redis, Postgres, etc).

## Deploy to Google Cloud Run

```bash
# One command
gcloud run deploy tcp-bridge \
  --source . \
  --allow-unauthenticated \
  --region us-central1
```

Done. You'll get a URL like: `https://tcp-bridge-abc123-uc.a.run.app`

## Usage

Connect via WebSocket with target host/port in query params:

```javascript
// Connect to Kafka
const ws = new WebSocket(
  "wss://tcp-bridge-abc123-uc.a.run.app/tcp?host=kafka.example.com&port=9092"
);

// Connect to Redis
const ws = new WebSocket(
  "wss://tcp-bridge-abc123-uc.a.run.app/tcp?host=redis.example.com&port=6379"
);

// Connect to Postgres
const ws = new WebSocket(
  "wss://tcp-bridge-abc123-uc.a.run.app/tcp?host=db.example.com&port=5432"
);
```

## Endpoints

| Path | Description |
|------|-------------|
| `/` | Service info (JSON) |
| `/health` | Health check |
| `/tcp?host=X&port=Y` | WebSocket → TCP bridge |

## Local Development

```bash
go run main.go
# Listening on :8080

# Test with websocat
websocat "ws://localhost:8080/tcp?host=localhost&port=9092"
```

## Architecture

```
Browser                    Cloud Run                 Target
┌──────────┐              ┌──────────┐              ┌──────────┐
│          │   WebSocket  │          │     TCP     │          │
│  WASM    │◄────────────►│  Bridge  │◄───────────►│  Kafka   │
│  Client  │              │          │              │  Redis   │
│          │              │          │              │  etc.    │
└──────────┘              └──────────┘              └──────────┘
```

The bridge has ZERO knowledge of the protocol. It just forwards bytes.

## Cost

Cloud Run free tier: 2 million requests/month
Typical usage: ~$0
# pure-kafka-prism
