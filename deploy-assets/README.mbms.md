<p align="center">
  <img src="https://raw.githubusercontent.com/HVR88/Limbo_DEV/main/assets/limbo-icon.png" alt="MusicBrainz" width="400" />
</p>

# <p align="center">**_MusicBrainz Mirror Server_**<br><sub>**Basic Full Stack (no Limbo Tools)**</sub></p>

## Introduction

MusicBrainz Mirror Server is a fully automated, complete MusicBrainz mirror stack. It packages the database, search, and indexing services so you can run a fast local mirror on your LAN.

> [!TIP]
>
> When deploying from a terminal, use _screen_ or _tmux_ so the compose process can continue running if your session drops (closing the window, computer goes to sleep, etc.)

## Requirements

- Linux server / VM / LXC with Docker support
- 300 GB of available storage (400-500 GB recommended)
- 8 GB of memory available to the container
- 2-4 hours installation time
- MusicBrainz account and Data Feed access token

## Quick start

### 1. Register for MusicBrainz access & token

- Create an account at https://MusicBrainz.com
- Get your _Live Data Feed Access Token_ from Metabrainz https://metabrainz.org/profile

### 2. Download the MusicBrainz-MBMS compose files (no git required)

Create a folder and download the latest `docker-compose.yml` and `example.env`
from the MusicBrainz-MBMS release assets (or the raw files in this repo).

```
mkdir -p /opt/docker/musicbrainz-mbms
cd /opt/docker/musicbrainz-mbms
```

### 3. Copy and configure env file

Copy `example.env` to `.env`, then edit the top section before first run:

```bash
cp example.env .env
```

- Set **`MUSICBRAINZ_REPLICATION_TOKEN`**
- Set the **`MUSICBRAINZ_REPLICATION_TOKEN`** (required for replication)
- `MUSICBRAINZ_WEB_SERVER_HOST` ('localhost' default, edit as needed)
- `MUSICBRAINZ_WEB_SERVER_PORT` ('5000' default, edit as needed)

Only `.env` is user-maintained. The stack refreshes managed files (admin scripts,
compose template, and defaults) automatically when you update.

### 4. Download containers, build DB & startup (!) This takes 2-4 hours

```
docker compose up -d
```

## Wrap-up

You can monitor the progress of the long first-time installation jobs from another terminal:

```
docker compose logs -f --timestamps
```

Or with less "noise:"

```
docker compose logs -f --no-log-prefix --tail=200 \
  bootstrap search-bootstrap search musicbrainz indexer indexer-cron

```

## Browser access / status

When finished, your MusicBrainz mirror will be available at **http://HOST_IP:5000**

> [!TIP]
>
> Put a reverse proxy (NPM, Caddy, Traefik, SWAG) in front of your host IP and use your own (sub)domain to reach your MusicBrainz mirror on port 80 (HTTP) or 443 (HTTPS) on your LAN

## Updates

Pull the latest images and restart:

```
docker compose pull
docker compose up -d
```

If a release updates `docker-compose.yml`, run `docker compose up -d` again
after the first restart so the new compose file is applied.

## Migration note (repo rename)

If you previously cloned the old deploy repo, update your git remote once:

1. `git remote set-url origin https://github.com/HVR88/MusicBrainz-MBMS`
2. `git pull`

If you were using zip downloads, replace your `docker-compose.yml` and
`example.env` with the new release assets, then re-apply your `.env` settings.
Example:

```bash
mkdir -p /opt/docker/musicbrainz-mbms
cd /opt/docker/musicbrainz-mbms
curl -fsSL -o musicbrainz-mbms-latest.zip https://github.com/HVR88/MusicBrainz-MBMS/releases/latest/download/musicbrainz-mbms-1.9.12.zip
unzip -o musicbrainz-mbms-latest.zip
```

## Migration note (volume prefix and upgrade)

Older installs did not set `COMPOSE_PROJECT_NAME`. Docker Compose used the
folder name as the project name, which is why volumes are prefixed `mbms_plus_`.
If you rename the folder, Compose will look for new volumes unless you pin the
project name.

You have two options:

1. **Keep using existing `mbms_plus_*` volumes (no migration)**
   - Keep the folder name as `mbms_plus`, **or**
   - Replace `docker-compose.yml` and `example.env` with the new release assets
     (image names changed to `limbo-*`), then re-apply your `.env` values.
     Example:
     ```bash
     curl -fsSL -o musicbrainz-mbms-latest.zip https://github.com/HVR88/MusicBrainz-MBMS/releases/latest/download/musicbrainz-mbms-1.9.12.zip
     unzip -o musicbrainz-mbms-latest.zip
     ```
   - Set `COMPOSE_PROJECT_NAME=mbms_plus` in `.env`.

2. **Migrate to new `limbo_*` volumes (recommended for new layout)**
   - Set `COMPOSE_PROJECT_NAME=limbo` in `.env`.
   - Replace `docker-compose.yml` and `example.env` with the new release assets
     (image names changed to `limbo-*`), then re-apply your `.env` values.
     Example:
     ```bash
     curl -fsSL -o musicbrainz-mbms-latest.zip https://github.com/HVR88/MusicBrainz-MBMS/releases/latest/download/musicbrainz-mbms-1.9.12.zip
     unzip -o musicbrainz-mbms-latest.zip
     ```
   - Run the migration script:
     ```bash
     admin/upgrade-volumes
     ```
   - Then start the stack:
     ```bash
     docker compose up -d
     ```

The migration script copies data from `mbms_plus_*` to `limbo_*` volumes and
merges any old Limbo init-state volumes into the single pinned
`limbo_bridge_init_state` volume.

## Notes

- _The first import and database setup will take multiple hours and requires up to 300GB of available storage_
- Building Materialized/denormalized tables consumes additional storage but offers significant performance improvements
- 60GB of pre-built search indexes are downloaded to save a significant amount of time building new indexes
- _Continued (scheduled) replication and indexing is required to keep the database up-to-date and at optimal performance_
- This stack is configured for private use on a LAN, behind a firewall
- _Don't expose services publicly without hardening_

> [!NOTE]
>
> MusicBrainz-MBMS is for personal use only: **NO COMMERCIAL OR BUSINESS USE IS PERMITTED**

### Source code, licenses and development repo:

https://github.com/HVR88/Limbo-MusicBrainz_DEV

## Maintenance (optional)

These helper scripts are synced into `admin/` automatically when the stack starts or updates:

- `admin/status` (show container status)
- `admin/logs [services...]` (follow logs)
- `admin/restart [services...]` (restart services)
- `admin/replicate-now` (trigger replication immediately)
- `admin/reindex-now` (trigger search reindex)
- `admin/bootstrap-reset` (clear bootstrap markers; prompts for confirmation)
