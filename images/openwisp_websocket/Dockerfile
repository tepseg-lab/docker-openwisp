# hadolint ignore=DL3007
FROM tepseg-lab/tepseg-base:latest

WORKDIR /opt/openwisp/

COPY daphne.conf \
     /opt/openwisp/
COPY module_settings.py \
     urls.py \
     /opt/openwisp/openwisp/

ARG WEBSOCKET_APP_PORT=8002
ENV MODULE_NAME=websocket \
    DJANGO_WEBSOCKET_HOST=0.0.0.0 \
    CONTAINER_PORT=$WEBSOCKET_APP_PORT

EXPOSE $WEBSOCKET_APP_PORT
CMD ["supervisord", "--nodaemon", "--configuration", "daphne.conf"]
