# Justfile

# Variables
# IMAGE_NAME := "fastapi-uv:latest"

# List 📜 all recipes (default)
help:
    @just --list

# Boring 😑 Hello world
default:
    echo 'Hello, world!'

# Start 🚀 the Dagger engine
start-dagger:
    # Set the Dagger version
    # export DAGGER_VERSION="v0.13.6"
    # export DAGGER_ENGINE_IMAGE="registry.dagger.io/engine:${DAGGER_VERSION}"
    # export DAGGER_ENGINE_NAME="dagger-engine-${DAGGER_VERSION}"

    # Stop and remove the existing Dagger engine
    -docker stop ${DAGGER_ENGINE_NAME}
    -docker rm  ${DAGGER_ENGINE_NAME}

    # Start the Dagger engine
    docker run -d \
    --name ${DAGGER_ENGINE_NAME} \
    --privileged \
    --network host \
    --restart always \
    -v dagger_engine_data:/var/lib/dagger \
    -v ./certs/rootCA.pem:/usr/local/share/ca-certificates/rootCA.pem \
    -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    -e DAGGER_GO_SDK_MANIFEST_DIGEST=${DAGGER_GO_SDK_MANIFEST_DIGEST} \
    -e DAGGER_PYTHON_SDK_MANIFEST_DIGEST=${DAGGER_PYTHON_SDK_MANIFEST_DIGEST} \
    -e DAGGER_TYPESCRIPT_SDK_MANIFEST_DIGEST=${DAGGER_TYPESCRIPT_SDK_MANIFEST_DIGEST} \
    -e _EXPERIMENTAL_DAGGER_RUNNER_HOST=unix:///var/run/buildkit/buildkitd.sock \
    ${DAGGER_ENGINE_IMAGE} \
    dagger-entrypoint.sh --debug

    @# -v /var/lib/dagger \

# Start 🚀 the Dagger engine
start-compose-dagger *args:
    -docker stop ${DAGGER_ENGINE_NAME}
    -docker rm  ${DAGGER_ENGINE_NAME}
    docker compose -f compose.yaml  --profile dagger up {{args}}

# Start 🚀 Traefik and the Dagger custom engine
start-compose-dagger-and-traefik:
    docker compose -f compose.yaml  --profile full up

# Start 🚀 Traefik and the Dagger custom engine, detaching 🫥
start-compose-dagger-and-traefik-background:
    docker compose -f compose.yaml  --profile full up --detach
