ARG MUSICBRAINZ_SERVER_VERSION=v-2026-01-19.0
ARG MUSICBRAINZ_BUILD_SEQUENCE=1
FROM metabrainz/musicbrainz-docker-musicbrainz:${MUSICBRAINZ_SERVER_VERSION}-build${MUSICBRAINZ_BUILD_SEQUENCE}

COPY bootstrap.sh /usr/local/bin/bootstrap.sh
RUN chmod 0755 /usr/local/bin/bootstrap.sh
