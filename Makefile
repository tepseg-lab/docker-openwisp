# Find documentation in README.md under
# the heading "Makefile Options".

SHELL := /bin/bash
.SILENT: clean pull start stop

default: compose-build

# Pull
USER = registry.gitlab.com/tepseg-lab1/docker-openwisp
TAG  = latest
pull:
	printf '\e[1;34m%-6s\e[m\n' "Downloading OpenWISP images..."
	for image in 'tepseg-base' 'openwisp-nfs' 'openwisp-api' 'openwisp-dashboard' \
				 'openwisp-freeradius' 'openwisp-nginx' 'openwisp-openvpn' 'openwisp-postfix' \
				 'openwisp-websocket' ; do \
		docker pull --quiet $(USER)/$${image}:$(TAG) &> /dev/null; \
		docker tag  $(USER)/$${image}:$(TAG) tepseg-lab/$${image}:latest; \
	done

# Build
python-build: build.py
	python build.py change-secret-key

base-build:
	BUILD_ARGS_FILE=$$(cat .build.env 2>/dev/null); \
	for build_arg in $$BUILD_ARGS_FILE; do \
	    BUILD_ARGS+=" --build-arg $$build_arg"; \
	done; \
	docker build --tag tepseg-lab/tepseg-base:intermedia-system \
	             --file ./images/openwisp_base/Dockerfile \
	             --target SYSTEM ./images/; \
	docker build --tag tepseg-lab/tepseg-base:intermedia-python \
	             --file ./images/openwisp_base/Dockerfile \
	             --target PYTHON ./images/ \
	             --build-arg SSH_PRIVATE_KEY="$$(cat .env | grep SSH_PRIVATE_KEY | cut -d '=' -f 2)" \
	             $$BUILD_ARGS; \
	docker build --tag tepseg-lab/tepseg-base:latest \
	             --file ./images/openwisp_base/Dockerfile ./images/ \
	             $$BUILD_ARGS

nfs-build:
	docker build --tag tepseg-lab/openwisp-nfs:latest \
	             --file ./images/openwisp_nfs/Dockerfile ./images/

compose-build: base-build
	docker-compose build --parallel

# Test
runtests: develop-runtests
	docker-compose stop

develop-runtests:
	docker-compose up -d
	python3 tests/runtests.py

# Development
develop: compose-build
	docker-compose up -d
	docker-compose logs -f

# Clean
clean:
	printf '\e[1;34m%-6s\e[m\n' "Removing docker-openwisp..."
	docker-compose stop &> /dev/null
	docker-compose down --remove-orphans --volumes --rmi all &> /dev/null
	docker-compose rm -svf &> /dev/null
	docker rmi --force tepseg-lab/tepseg-base:latest \
				tepseg-lab/tepseg-base:intermedia-system \
				tepseg-lab/tepseg-base:intermedia-python \
				tepseg-lab/openwisp-nfs:latest \
				`docker images -f "dangling=true" -q` \
				`docker images | grep tepseg-lab/docker-openwisp | tr -s ' ' | cut -d ' ' -f 3` &> /dev/null

# Production
USER = registry.gitlab.com/tepseg-lab1/docker-openwisp
TAG  = latest
start: pull
	printf '\e[1;34m%-6s\e[m\n' "Starting Services..."
	docker-compose --log-level WARNING up -d
	printf '\e[1;32m%-6s\e[m\n' "Success: OpenWISP should be available at your dashboard domain in 2 minutes."

stop:
	printf '\e[1;31m%-6s\e[m\n' "Stopping OpenWISP services..."
	docker-compose --log-level ERROR stop
	docker-compose --log-level ERROR down --remove-orphans
	docker-compose down --remove-orphans &> /dev/null

# Publish
USER = registry.gitlab.com/tepseg-lab1/docker-openwisp
TAG  = latest
SKIP_BUILD = false
SKIP_TESTS = false

publish:
	if [[ "$(SKIP_BUILD)" == "false" ]]; then \
		make compose-build nfs-build; \
	fi
	if [[ "$(SKIP_TESTS)" == "false" ]]; then \
		make runtests; \
	fi
	for image in 'tepseg-base' 'openwisp-nfs' 'openwisp-api' 'openwisp-dashboard' \
				 'openwisp-freeradius' 'openwisp-nginx' 'openwisp-openvpn' 'openwisp-postfix' \
				 'openwisp-websocket' ; do \
		docker tag tepseg-lab/$${image}:latest $(USER)/$${image}:$(TAG); \
		docker push $(USER)/$${image}:$(TAG); \
		docker rmi $(USER)/$${image}:$(TAG); \
		if [[ "$(TAG)" != "edge" ]] && [[ "$(TAG)" != "latest" ]]; then \
			docker tag tepseg-lab/$${image}:latest $(USER)/$${image}:latest; \
			docker push $(USER)/$${image}:latest; \
			docker rmi $(USER)/$${image}:latest; \
		fi \
	done
