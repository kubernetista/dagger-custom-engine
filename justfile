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
    export DAGGER_VERSION="v0.13.6"
    export DAGGER_ENGINE_IMAGE="registry.dagger.io/engine:${DAGGER_VERSION}"
    export DAGGER_ENGINE_NAME="dagger-engine-${DAGGER_VERSION}"

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
    -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    -e DAGGER_GO_SDK_MANIFEST_DIGEST=sha256:52eb9e0fd4a27ec1c6cfe2ce48af52bf4c20615f733e6f8fb827b6340e109a99 \
    -e DAGGER_PYTHON_SDK_MANIFEST_DIGEST=sha256:998b96cd1402c7846ad8083bf02bbef4e3ef05ce1636b6a7cfa90339b9f6f1f5 \
    -e DAGGER_TYPESCRIPT_SDK_MANIFEST_DIGEST=sha256:2ff9d99098fb01843067de08f7966c4d7371497e10ca64e958d5e714d50d2024 \
    -e _EXPERIMENTAL_DAGGER_RUNNER_HOST=unix:///var/run/buildkit/buildkitd.sock \
    ${DAGGER_ENGINE_IMAGE} \
    dagger-entrypoint.sh --debug

    # -v /var/lib/dagger \

# Start 🚀 the Dagger engine
start-compose-dagger:
    docker compose -f compose.yaml  --profile dagger up

# Start 🚀 Traefik and the Dagger custom engine
start-compose-dagger-and-traefik:
    docker compose -f compose.yaml  --profile full up

# Start 🚀 Traefik and the Dagger custom engine, detaching 🫥
start-compose-dagger-and-traefik-background:
    docker compose -f compose.yaml  --profile full up --detach
