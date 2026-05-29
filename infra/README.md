# Tracelet AWS infrastructure

Region: **`ap-northeast-1` (Tokyo)** — primary market Japan.

No S3. No long-term message storage. Async payloads stay inline in DynamoDB/SQS (≤256 KB).

## Architecture

```text
Flutter app
  ├─ HTTPS  → API Gateway HTTP  → Lambda (async: direct, bottle, settings)
  └─ WSS    → API Gateway WS    → Lambda (live bidirectional point relay)

DynamoDB
  ├─ users            profile + defaultPenColor + settings
  ├─ friendships
  ├─ presence         live-session targeting (TTL)
  ├─ connections      WebSocket connectionId → userId
  └─ pending-direct   one-shot direct messages (TTL 24h, delete on fetch)

SQS FIFO
  └─ bottle-ocean     anonymous bottles, delete on pull, 24h retention
```

## Live session (bidirectional, option 1)

Both users in `specificUserSend` targeting each other. Neither sees the other's IP.

1. Client opens WebSocket to API Gateway (Tokyo).
2. Client sends `presence` heartbeat.
3. When mutual targeting is detected, server pushes `liveSession` to **both** clients with peer color.
4. Each pan move sends `point`; Lambda relays to peer's connection only (no persistence).

### WebSocket protocol

Connect (temporary until Cognito authorizer is attached to `$connect`):

```text
wss://{api-id}.execute-api.ap-northeast-1.amazonaws.com/dev?userId={cognitoSub}
Authorization: Bearer {jwt}
```

**Client → server**

```json
{ "action": "presence", "mode": "specificUserSend", "targetUserId": "peer-id" }
```

```json
{ "action": "point", "x": 0.42, "y": 0.61, "t": 1200, "break": false, "color": "#007AFF" }
```

`color` is optional; server falls back to the sender's `defaultPenColor` from DynamoDB.

**Server → client**

```json
{
  "type": "liveSession",
  "peerId": "peer-id",
  "peerDisplayName": "Alice",
  "peerColor": "#34C759",
  "bidirectional": true
}
```

```json
{
  "type": "point",
  "fromUserId": "peer-id",
  "x": 0.42,
  "y": 0.61,
  "t": 1200,
  "break": false,
  "color": "#34C759"
}
```

```json
{ "type": "liveSessionEnded", "reason": "peerDisconnected" }
```

Each user draws in their own color simultaneously. Render peer points using `color` from the payload.

## Default pen color

Stored on the user profile (`users.defaultPenColor`, default `#007AFF`).

```http
GET  /settings
PUT  /settings  { "defaultPenColor": "#34C759", "muted": false, ... }
```

Flutter `AppSettings` will need a matching field when wiring the client.

## Async messaging (no archive)

| Flow | Storage | Lifetime |
|---|---|---|
| Direct send | DynamoDB `pending-direct` | Delete on fetch; TTL 24h if unread |
| Bottle deposit | SQS FIFO | Delete on pull; queue retention 24h |
| Live points | None | Relay only |

## Deploy (dev)

Prerequisites:

1. **Terraform** ≥ 1.5 and **AWS CLI** v2 (installed via winget on Windows).
2. **AWS credentials** for `ap-northeast-1` with permissions to create Cognito, DynamoDB, SQS, Lambda, API Gateway, IAM, and CloudWatch Logs.

### 1. Configure AWS

Pick one:

```bash
# Access keys
aws configure
# Region: ap-northeast-1
# Output: json

# Or SSO
aws configure sso
```

Verify:

```bash
aws sts get-caller-identity
```

### 2. Deploy

From the repo root (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File infra/scripts/deploy-dev.ps1 -PlanOnly   # review first
powershell -ExecutionPolicy Bypass -File infra/scripts/deploy-dev.ps1             # apply
```

Or manually:

```bash
cd infra/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # already gitignored
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Save outputs — the Flutter app will need `http_api_url`, `websocket_api_url`, Cognito IDs.

### 3. Automated tests

All local tests (no human interaction):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-all-tests.ps1
```

Unit/widget tests only (no AWS):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-all-tests.ps1 -SkipAws
```

Smoke tests against the deployed dev stack (Cognito user is created/confirmed via Admin API — no email inbox):

```powershell
powershell -ExecutionPolicy Bypass -File infra/scripts/smoke-test-dev.ps1
```

`deploy-dev.ps1` runs smoke tests automatically after a successful apply (use `-SkipTests` to skip).

Optional env overrides for smoke credentials:

- `TRACELET_SMOKE_EMAIL`
- `TRACELET_SMOKE_PASSWORD`

Default smoke user: `tracelet-smoke-test@tracelet.dev` / `TraceletSmoke1`

CI (GitHub Actions): Flutter tests + trace validation on every push/PR. Live AWS smoke via **Actions → Test → Run workflow** with `run_aws_smoke` enabled (requires `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` secrets).

### 4. Tear down (when done experimenting)

```bash
cd infra/terraform/environments/dev
terraform destroy
```

## Next steps

- Attach Cognito JWT authorizer to WebSocket `$connect` and HTTP routes.
- Replace `?userId=` query param with JWT `sub` in `ws-connect`.
- Wire Flutter repositories to HTTP/WebSocket endpoints.
- Add `defaultPenColor` to `AppSettings` and settings UI.
- Enforce 10-second trace cap client-side before send.

## Lambda layout

| Function | Role |
|---|---|
| `ws-connect` | Register connectionId → userId |
| `ws-disconnect` | Tear down presence + notify peer |
| `ws-relay` | Mutual presence + bidirectional point relay |
| `api` | Settings, direct messages, bottle deposit/pull |

Handlers use AWS SDK v3 included in the Node.js 20 Lambda runtime.
