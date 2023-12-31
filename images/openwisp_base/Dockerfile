FROM python:3.10-slim-bullseye AS system

# System requirements:
# 1. gettext: Required by envsubst used in scripts
# 2. openwisp-radius/weasyprint: libcairo2 libpangocairo-1.0
# 3. openwisp-monitoring: fping gdal-bin
# hadolint ignore=DL3008

RUN apt-get update

RUN apt-get install --yes --no-install-recommends \
    libcairo2 apt-utils libpangocairo-1.0-0 \
    gdal-bin gettext fping && \
    rm -rf /var/lib/apt/lists/* /root/.cache/pip/* /tmp/*
# hadolint ignore=DL3008, DL3009
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    gcc libpq-dev libjpeg-dev libffi-dev python3-dev \
    python3-pip libxml2-dev libxslt1-dev zlib1g-dev g++ procps \
    git ssh

COPY ./openwisp_base/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN useradd --system --password '' --create-home --shell /bin/bash \
   --gid root --groups sudo --uid 1001 openwisp
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

FROM system AS openwisp_python

ENV PYTHONPATH=/install/lib/python3.10/site-packages

RUN pip install --no-cache-dir  --prefix='/install' --upgrade pip~=23.0.1
# TODO: Remove when next version of openwisp-monitoring is released
ARG OPENWISP_MONITORING_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-monitoring.git@main
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --prefix='/install' --upgrade ${OPENWISP_MONITORING_SOURCE}
ARG OPENWISP_FIRMWARE_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-firmware-upgrader.git@main
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --prefix='/install' --upgrade ${OPENWISP_FIRMWARE_SOURCE}
ARG OPENWISP_TOPOLOGY_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-network-topology.git@main
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --prefix='/install' --upgrade ${OPENWISP_TOPOLOGY_SOURCE}
ARG OPENWISP_RADIUS_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-radius.git@main
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --prefix='/install' --upgrade ${OPENWISP_RADIUS_SOURCE}

# here we try to install custom versions of the modules only if the
# supplied argument does not equal the default value, because
# otherwise these modules will have already been installed above
ARG OPENWISP_IPAM_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-ipam.git@main
# hadolint ignore=DL3013
RUN if [ "$OPENWISP_IPAM_SOURCE" != "default" ] ; then \
        pip install --no-cache-dir --prefix='/install' --upgrade ${OPENWISP_IPAM_SOURCE}; \
    fi
# TODO: Remove when next version of openwisp-controller is released
ARG OPENWISP_CONTROLLER_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-controller.git@main
# hadolint ignore=DL3013
RUN if [ "$OPENWISP_CONTROLLER_SOURCE" != "default" ] ; then \
        pip install --no-cache-dir --prefix='/install' --upgrade ${OPENWISP_CONTROLLER_SOURCE}; \
    fi
ARG OPENWISP_NOTIFICATION_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-notifications.git@main
# hadolint ignore=DL3013
RUN if [ "$OPENWISP_NOTIFICATION_SOURCE" != "default" ] ; then \
        pip install --no-cache-dir --prefix='/install' --upgrade ${OPENWISP_NOTIFICATION_SOURCE}; \
    fi
ARG OPENWISP_USERS_SOURCE=git+ssh://git@github.com/tepseg-lab/openwisp-users.git@main
# hadolint ignore=DL3013
RUN if [ "$OPENWISP_USERS_SOURCE" != "default" ] ; then \
        pip install --no-cache-dir --prefix='/install' --upgrade --force-reinstall ${OPENWISP_USERS_SOURCE}; \
    fi
# TODO: Remove when next version of openwisp-utils is released
ARG OPENWISP_UTILS_SOURCE="openwisp-utils[celery,rest] @ git+ssh://git@github.com/tepseg-lab/openwisp-utils.git@main "
# hadolint ignore=DL3013
RUN if [ "$OPENWISP_UTILS_SOURCE" != "default" ] ; then \
        pip install --no-cache-dir --prefix='/install' --upgrade --force-reinstall "${OPENWISP_UTILS_SOURCE}"; \
    fi
ARG DJANGO_X509_SOURCE=git+ssh://git@github.com/tepseg-lab/django-x509.git@main
# hadolint ignore=DL3013
RUN if [ "$DJANGO_X509_SOURCE" != "default" ]; then \
        pip install --no-cache-dir --prefix='/install' --upgrade --force-reinstall ${DJANGO_X509_SOURCE}; \
    fi

ARG DJANGO_SOURCE=django~=4.0.10
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --prefix='/install' --upgrade ${DJANGO_SOURCE}

COPY ./openwisp_base/requirements.txt /tmp/openwisp-deploy-requirements.txt
RUN pip install --no-cache-dir --prefix='/install' --upgrade -r /tmp/openwisp-deploy-requirements.txt

FROM system

COPY --from=openwisp_python /install /usr/local
COPY ./common/ /opt/openwisp/
RUN mkdir /opt/openwisp/static && mkdir /opt/openwisp/media && mkdir /opt/openwisp/private && \
    mkdir /opt/openwisp/logs

ENV DASHBOARD_APP_SERVICE=dashboard \
    PYTHONUNBUFFERED=1 \
    TZ=UTC \
    DEBUG_MODE=False \
    REDIS_HOST=redis \
    DB_ENGINE=django.contrib.gis.db.backends.postgis \
    DB_NAME=openwisp_db \
    DB_USER=admin \
    DB_PASS=admin \
    DB_HOST=postgres \
    DB_PORT=5432 \
    DB_SSLMODE=disable \
    DB_SSLKEY=None \
    DB_SSLCERT=None \
    DB_SSLROOTCERT=None \
    DB_OPTIONS={} \
    INFLUXDB_USER=admin \
    INFLUXDB_PASS=admin \
    INFLUXDB_NAME=openwisp \
    INFLUXDB_HOST=influxdb \
    INFLUXDB_PORT=8086 \
    INFLUXDB_DEFAULT_RETENTION_POLICY=26280h0m0s \
    EMAIL_BACKEND=djcelery_email.backends.CeleryEmailBackend \
    EMAIL_HOST=postfix \
    EMAIL_HOST_PORT=25 \
    EMAIL_HOST_USER="" \
    EMAIL_HOST_PASSWORD="" \
    EMAIL_HOST_TLS=False \
    EMAIL_TIMEOUT=10 \
    EMAIL_DJANGO_DEFAULT=example@example.org \
    DJANGO_LOG_LEVEL=ERROR \
    DJANGO_LANGUAGE_CODE=en-gb \
    DJANGO_FREERADIUS_ALLOWED_HOSTS=172.18.0.0/16 \
    DJANGO_X509_DEFAULT_CERT_VALIDITY=1825 \
    DJANGO_X509_DEFAULT_CA_VALIDITY=3650 \
    DJANGO_SECRET_KEY=DEFAULT_BAD_KEY \
    DJANGO_CORS_HOSTS=http://localhost \
    DJANGO_SENTRY_DSN="" \
    DJANGO_LEAFET_CENTER_X_AXIS=0 \
    DJANGO_LEAFET_CENTER_Y_AXIS=0 \
    DJANGO_LEAFET_ZOOM=1 \
    # Common Nginx configurations
    NGINX_CLIENT_BODY_SIZE=30 \
    DASHBOARD_APP_PORT=8000 \
    API_APP_PORT=8001 \
    WEBSOCKET_APP_PORT=8002 \
    DASHBOARD_INTERNAL=dashboard.internal \
    API_INTERNAL=api.internal \
    # VPN Configurations
    VPN_DOMAIN=openvpn.example.com \
    VPN_NAME=default \
    VPN_CLIENT_NAME=default-management-vpn \
    X509_NAME_CA=default \
    X509_NAME_CERT=default \
    X509_COUNTRY_CODE=IN \
    X509_STATE=Delhi \
    X509_CITY="New Delhi" \
    X509_ORGANIZATION_NAME=OpenWISP \
    X509_ORGANIZATION_UNIT_NAME=OpenWISP \
    X509_EMAIL=certificate@example.com \
    X509_COMMON_NAME=OpenWISP \
    # Modules Enabled
    USE_OPENWISP_RADIUS=True \
    USE_OPENWISP_TOPOLOGY=True \
    USE_OPENWISP_FIRMWARE=True \
    USE_OPENWISP_MONITORING=True \
    # Celery-beat Configurations
    CRON_DELETE_OLD_RADACCT=365 \
    CRON_DELETE_OLD_POSTAUTH=365 \
    CRON_CLEANUP_STALE_RADACCT=365 \
    CRON_DELETE_OLD_USERS=12
