# Railway installation

This fork adds a Railway deployment of the existing Tel-Agent dashboard and API.
It does not claim working telephone answering: upstream has voice transport classes,
but no executable voice worker, dispatch loop or startup command.

## Services

| Service | Dockerfile | Network | Persistent storage |
| --- | --- | --- | --- |
| api | docker/api.Dockerfile | Private, port 38472 | /data volume |
| web | docker/web.Dockerfile | Private, port 38471 | None |
| gateway | docker/gateway.Dockerfile | Public HTTPS, target port 8080 | None |

Use one API replica. SQLite lives at /data/tel-agent.db. The image links /app/var
to /data/var so backups, recordings and restore requests survive redeployment.
On Railway set RAILWAY_RUN_UID=0 for the API volume initialization; the entrypoint
immediately drops to the existing telagent user before migrations and serving.

API variables: ENVIRONMENT=production, DATABASE_URL=sqlite+aiosqlite:////data/tel-agent.db,
BIND_HOST=0.0.0.0, BIND_PORT=38472, ENCRYPTION_KEY (random 64-character hex),
CORS_ORIGINS and PUBLIC_BASE_URL (the gateway HTTPS origin),
TRUSTED_HOSTS (gateway hostname, api.railway.internal, healthcheck.railway.app,
localhost,127.0.0.1), HSTS_SECONDS=31536000, TZ=Europe/Berlin.

Web variables: NEXT_PUBLIC_API_URL (gateway HTTPS origin, required at build time),
PORT=38471, HOSTNAME=0.0.0.0. Each service selects its Dockerfile using
RAILWAY_DOCKERFILE_PATH. API health check: /health. Gateway health check: /health.

The gateway preserves API paths and forwards streaming responses immediately.
One public origin keeps the existing Secure, HttpOnly, SameSite=Lax session cookies
working without relaxing authentication or CSRF protections.

## First run and updates

1. Deploy API and web while the gateway is stopped. Never expose anonymous setup.
2. Through Railway SSH, POST /api/setup on loopback to create the owner account.
   Use a random password, locale de, and the operator's workspace name.
3. Check setup is no longer needed and rejects a second initialization (409).
4. Deploy the gateway, then verify HTTPS login, health, authenticated API access,
   forbidden anonymous access and database persistence across a restart.
5. Keep the encryption key in Railway variables and a separate encrypted recovery
   store. Never commit it or store it beside the database backup.
6. Keep a volume backup before upgrades. Deploy only the reviewed deployment branch.

No AI, speech, SIP or messaging provider credentials are supplied by this fork.
Set customer-owned credentials in the application's settings. Telephone activation
also requires implementing the missing worker and validating incoming calls with
LiveKit/SIP. CAVOS integration is a separate later task; this deployment does not
change CAVOS or existing telephone routing.
