<p align="center">
  <img src="https://raw.githubusercontent.com/HVR88/LM-Bridge-DEV/main/assets/lmbridge-icon.png" alt="LM Bridge" width="250" />
</p>

# MusicBrainz Mirror Server PLUS (MBMS DEV)

This repo contains a streamlined, automation-first wrapper around the official MusicBrainz Docker stack plus a custom Lidarr/MusicBrainz API bridge. It keeps the modern multi-service architecture (Postgres, Solr, SIR, RabbitMQ, Redis) but removes the multi-step manual setup by adding bootstrap and scheduling services.

> [!NOTE]
>
> **To deploy pre-built docker containers clone the production repo: https://github.com/HVR88/MBMS_PLUS**

## Highlights

- One-command bring-up with automatic database import
- Materialized tables built by default
- Prebuilt Solr indexes downloaded by default
- Replication and indexing schedules controlled via simple env values
- Helper scripts for first run, validation, and manual jobs
- API Bridge betwallowing cached queries from Lidarr to MusicBrainz

## Quick start

0. Get your Live Data Feed Access Token from Metabrainz first
   https://metabrainz.org/profile

1. Edit `.env` (included in this repo) to match your environment.

2. Start everything (bootstrap + services):

```bash
./run.sh
```

That’s it. The initial import and indexing can take hours and consume significant disk.

## Configuration

Edit `.env` for the most common settings. The file is organized with a “common” section at the top and advanced settings below.

Common settings:

- `MUSICBRAINZ_WEB_SERVER_HOST`
- `MUSICBRAINZ_WEB_SERVER_PORT`
- `STATIC_RESOURCES_LOCATION`
- `MUSICBRAINZ_SERVER_PROCESSES`
- `MUSICBRAINZ_NETWORK_TYPE` (bridge | macvlan | ipvlan)
- `MUSICBRAINZ_NETWORK_PARENT` (required for macvlan/ipvlan)
- `MUSICBRAINZ_NETWORK_SUBNET` (CIDR, required for macvlan/ipvlan)
- `MUSICBRAINZ_NETWORK_GATEWAY` (required for macvlan/ipvlan)
- `MUSICBRAINZ_NETWORK_IP` (optional static IP for musicbrainz on macvlan/ipvlan)
- `MUSICBRAINZ_IPVLAN_MODE` (l2 | l3, optional for ipvlan)
- `MUSICBRAINZ_REPLICATION_ENABLED`
- `MUSICBRAINZ_REPLICATION_TIME` (HH:MM, 24-hour)
- `MUSICBRAINZ_REPLICATION_TOKEN`
- `MUSICBRAINZ_INDEXING_ENABLED`
- `MUSICBRAINZ_INDEXING_TIME` (HH:MM, 24-hour)
- `MUSICBRAINZ_INDEXING_DAY` (English day name)
- `MUSICBRAINZ_INDEXING_FREQUENCY` (daily | weekly | biweekly)
- `POSTGRES_SHARED_BUFFERS`
- `POSTGRES_SHM_SIZE`
- `SOLR_HEAP`
- `LMBRIDGE_IMAGE` (LM-Bridge)
- `LMBRIDGE_PORT` (LM-Bridge)
- `LMBRIDGE_NETWORK_IP` (LM-Bridge, macvlan/ipvlan only)

Advanced settings are below the divider in `.env` and generally do not need changes.

## LM-Bridge (optional)

LM-Bridge is included by default via `compose/lm-bridge.yml` and exposes port `5001`.
It runs on the internal network and connects to the existing `db`, `search`, and
`redis` services.

When `MUSICBRAINZ_NETWORK_TYPE` is `macvlan` or `ipvlan`, LM-Bridge is also
attached to the `lan` network. Set `LMBRIDGE_NETWORK_IP` if you want a static
LAN IP; otherwise Docker will assign one.

To see the assigned IPs for LM-Bridge (including the `lan` network when used):

```bash
docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{println $k $v.IPAddress}}{{end}}' $(docker compose ps -q lmbridge)
```

To disable LM-Bridge, remove `compose/lm-bridge.yml` from `COMPOSE_FILE` in `.env`.

## Network mode

By default everything runs on the standard bridge network. If you set
`MUSICBRAINZ_NETWORK_TYPE` to `macvlan` or `ipvlan`, the `musicbrainz`
service is attached to a second `lan` network so it can receive a LAN IP.
Other services remain on the bridge network for internal communication.

When switching to `macvlan` or `ipvlan`, regenerate the network override:

```bash
admin/render-network
```

## Replication

Replication is controlled by three env vars (enabled by default):

- `MUSICBRAINZ_REPLICATION_ENABLED=true|false`
- `MUSICBRAINZ_REPLICATION_TIME=HH:MM`
- `MUSICBRAINZ_REPLICATION_TOKEN=...`

When enabled, the container generates its own cron entry. The token can be provided directly via env.

Manual replication:

```bash
admin/replicate-now
```

## Search indexing schedule

If live indexing is not enabled, scheduled reindexing keeps search fresh.

Env controls:

- `MUSICBRAINZ_INDEXING_ENABLED=true|false`
- `MUSICBRAINZ_INDEXING_TIME=HH:MM`
- `MUSICBRAINZ_INDEXING_DAY=Sunday` (ignored when frequency is daily)
- `MUSICBRAINZ_INDEXING_FREQUENCY=daily|weekly|biweekly`

Manual reindex:

```bash
admin/reindex-now
```

## Bootstrap behavior

Bootstrap runs once on first startup and writes marker files into the shared volumes. It will skip future runs unless markers are removed.

To reset bootstrap markers:

```bash
admin/bootstrap reset
```

## Helper scripts

- `admin/first-run` – create `.env` from `.env.example`
- `admin/validate-env` – validate key env values
- `admin/preflight` – first-run + validate + `docker compose config`
- `admin/bootstrap` – enable/disable/reset bootstrap override
- `admin/replicate-now` – run replication immediately
- `admin/reindex-now` – run search reindex immediately
- `admin/update-upstream` – pull changes from upstream

## Publishing images

GitHub Actions builds and publishes images on push to `master`:

- GHCR: `ghcr.io/<owner>/<repo>/<service>`
- Docker Hub (optional): `docker.io/<username>/musicbrainz-docker/<service>`

To enable Docker Hub publishing, set repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Upstream updates

This repo is not a fork. Upstream is configured as:

- `origin` → your repo
- `upstream` → `metabrainz/musicbrainz-docker`

To update from upstream:

```bash
admin/update-upstream
```

## Notes

- First import and indexing can take hours and consume hundreds of GB.
- This setup keeps the official multi-service layout and adds automation.
- Solr and other service ports should not be exposed publicly without proper hardening.
