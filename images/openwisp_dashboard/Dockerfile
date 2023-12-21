# hadolint ignore=DL3007
FROM tepseg-lab/tepseg-base:latest
WORKDIR /opt/openwisp/

# Location: /opt/openwisp/
COPY ./load_init_data.py \
    ./openvpn.json \
    /opt/openwisp/
# Location: /opt/openwisp/openwisp/
COPY ./module_settings.py \
    ./urls.py \
    /opt/openwisp/openwisp/

CMD ["bash", "init_command.sh"]

ARG DASHBOARD_APP_PORT=8000
ENV MODULE_NAME=dashboard \
    CONTAINER_PORT=$DASHBOARD_APP_PORT

EXPOSE $DASHBOARD_APP_PORT
