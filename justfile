# Justfile

# Variables
# IMAGE_NAME := "fastapi-uv:latest"

# List 📜 all recipes (default)
help:
    @just --list

# Boring 😑 Hello world
default:
    echo 'Hello, world!'

# Start 🚀 the Dagger custom engine 🧪
start-dagger-custom:
    docker compose -f compose.yaml  --profile dagger up

# Start 🚀 Traefik and the Dagger custom engine
start-traefik-and-dagger-custom:
    docker compose -f compose.yaml  --profile full up

# Start 🚀 Traefik and the Dagger custom engine, detaching 🫥
start-traefik-and-dagger-custom-background:
    docker compose -f compose.yaml  --profile full up --detach
