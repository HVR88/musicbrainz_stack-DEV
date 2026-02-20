ARG MUSICBRAINZ_SERVER_VERSION=v-2026-01-19.0
ARG MUSICBRAINZ_BUILD_SEQUENCE=1
FROM metabrainz/musicbrainz-docker-musicbrainz:${MUSICBRAINZ_SERVER_VERSION}-build${MUSICBRAINZ_BUILD_SEQUENCE}

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 && \
    rm -rf /var/lib/apt/lists/*

# Overlay custom scripts and DBDefs.pm from this repo to keep
# the prebuilt image aligned with our runtime behavior.
COPY build/musicbrainz/DBDefs.pm /musicbrainz-server/lib/
COPY build/musicbrainz/scripts/ /usr/local/bin/
COPY build/musicbrainz/mbms-admin/ /opt/mbms-admin/
RUN chmod +x /opt/mbms-admin/start-mbms-admin.sh /opt/mbms-admin/listener.py
