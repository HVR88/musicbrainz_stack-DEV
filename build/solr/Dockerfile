ARG MB_SOLR_VERSION=4.1.0
FROM metabrainz/mb-solr:${MB_SOLR_VERSION}

ARG MB_SOLR_VERSION
LABEL org.metabrainz.based-on-image="metabrainz/mb-solr:${MB_SOLR_VERSION}"

COPY --chmod=0755 scripts/bootstrap-indexes.sh /usr/local/bin/bootstrap-indexes.sh
