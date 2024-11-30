# Dagger Custom Engine

_Original name: Dagger: publish to a (k3d) local registry_

Follow the steps to start a custom dagger engine, that includes the local mkcert CA

At every new dagger release the engine version and the hashes of the sdks need to be updated.

UPDATE THE ENV VARS BELOW IN DIRENV (.envrc)

```sh
vim .envrc
##:
# Dagger
export DAGGER_VERSION="v0.14.0"

# The three vars below change at every dagger version (being hashes of the images)
export "DAGGER_GO_SDK_MANIFEST_DIGEST=sha256:0bbceb0c4f1c346d3408087273bce50bd6ffaa39d76d783b4c177421a984c5f0"
export "DAGGER_PYTHON_SDK_MANIFEST_DIGEST=sha256:c64096425c63f26e2e301643eb3a25f4e533881a8b49d87c2a596a2405c923eb"
export "DAGGER_TYPESCRIPT_SDK_MANIFEST_DIGEST=sha256:c0aa2496d90869c1c73451bd70780c572a29a849a7e96fbd334d840e405572ba"
```

## Start the dagger engine

```sh
just start-dagger

# or (⚠️ the compose dagger stops and does not restart after every job)
just start-compose-dagger
```

## Reference

- Custom CA
  - <https://docs.dagger.io/manuals/administrator/custom-ca/>

I Test di pubblicazione docker image li ho fatti dal progetto `fastapi-demo`:

```sh
cd fastapi-demo
# verificare la porta del k3d registry attualmente in uso (5000, 5001, 5002)
# ed eventualmente aggiornarlo nella funzione
dagger call publish-local
```

## Option 1: run with Docker Compose

```sh
# ⚠️ check compose.yml because there are environment variables in the docker compose that need
# to be updated every time the dagger version is updated
docker compose --profile full up
```

## Option 2: modify the dagger engine, connecting it to the host network (instead of the bridge)

```sh
# Set env vars
export DAGGER_VERSION="v0.13.7"
export DAGGER_ENGINE_IMAGE="registry.dagger.io/engine:${DAGGER_VERSION}"

# Set the normal engine name, to only have the host network and no other difference
# dagger-engine-v0.13.6
export DAGGER_ENGINE_NAME="dagger-engine-${DAGGER_VERSION}"


# stop and remove the current dagger runner
docker stop ${DAGGER_ENGINE_NAME}
docker rm ${DAGGER_ENGINE_NAME}

# Isolate the values that need to be updated in the compose file
docker container inspect dagger-engine-v0.13.7 | rg -i DAGGER_

# OR dump the config
docker inspect ${DAGGER_ENGINE_NAME} > dagger_inspect.json

# Start dagger in compose with just
just start-compose-dagger

# Start dagger with compose
docker compose -f compose.yaml  --profile dagger up

# pass the config through chatgpt and ask to keep all the relevant values, just replacing
# the bridge network with the host one

# for v0.13.6
docker run -d \
  --name ${DAGGER_ENGINE_NAME} \
  --network host \
  --privileged \
  --restart always \
  -v dagger_engine_data:/var/lib/dagger \
  -v ./certs/rootCA.pem:/usr/local/share/ca-certificates/rootCA.pem \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -e SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  -e DAGGER_GO_SDK_MANIFEST_DIGEST=sha256:52eb9e0fd4a27ec1c6cfe2ce48af52bf4c20615f733e6f8fb827b6340e109a99 \
  -e DAGGER_PYTHON_SDK_MANIFEST_DIGEST=sha256:998b96cd1402c7846ad8083bf02bbef4e3ef05ce1636b6a7cfa90339b9f6f1f5 \
  -e DAGGER_TYPESCRIPT_SDK_MANIFEST_DIGEST=sha256:2ff9d99098fb01843067de08f7966c4d7371497e10ca64e958d5e714d50d2024 \
  -e _EXPERIMENTAL_DAGGER_RUNNER_HOST=unix:///var/run/buildkit/buildkitd.sock \
  ${DAGGER_ENGINE_IMAGE} \
  dagger-entrypoint.sh --debug

# Other possible options for the volume mount
  -v /var/lib/docker/volumes/803b517089c40e3ce74e4d29741f36859eeef11e6800d2c07737ba9a91361838/_data:/var/lib/dagger \
  -v 124af10e4361f7a7e3b8a0c24342aedce87f07928266010acc87e1b01cd0a39a:/var/lib/dagger \
  -v dagger-engine:/var/lib/dagger \


# OR, set a custom engine name, in case it's useful
export DAGGER_ENGINE_NAME="dagger-engine-custom"

# for v0.13.3
docker run -d \
  --name ${DAGGER_ENGINE_NAME} \
  --network host \
  --privileged \
  --restart always \
  -v /var/lib/dagger \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -e SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  -e DAGGER_GO_SDK_MANIFEST_DIGEST=sha256:4421bf2cfd1def7fba1fb677c54e35dab63cf59f70df32bd04eb1738b1c90c17 \
  -e DAGGER_PYTHON_SDK_MANIFEST_DIGEST=sha256:c5c56696d7df8abb56f8de0998dc70026c75a2943fc06f8a41091ebc68f387ef \
  -e DAGGER_TYPESCRIPT_SDK_MANIFEST_DIGEST=sha256:7a02b582988ce4c66940e234198e8409b89827b3115bc504e8056b1577b00d83 \
  -e _EXPERIMENTAL_DAGGER_RUNNER_HOST=unix:///var/run/buildkit/buildkitd.sock \
  ${DAGGER_ENGINE_IMAGE} \
  dagger-entrypoint.sh --debug


# Set the runner to the custom dagger engine
export _EXPERIMENTAL_DAGGER_RUNNER_HOST="docker-container://${DAGGER_ENGINE_CUSTOM}"

# Try publish from fastapi-demo project
#  ⋯/_projects/Aruba-DevOps/fastapi-demo
dagger call publish-local --srv=tcp://localhost:5000
# this time it works! 🎉

# Check that the image is present on the registry
docker pull localhost:5001/test-user/my-nginx:dagger

crane catalog localhost:5000 --full-ref
http :5000/v2/_catalog

# Stop the custom Dagger Engine
docker stop ${DAGGER_ENGINE_CUSTOM}
docker rm ${DAGGER_ENGINE_CUSTOM}

```

## Test publish  using skopeo

```sh
# Push an image to Gitea
skopeo copy --override-os=linux --dest-tls-verify=false --dest-username="$DAGGER_REGISTRY_USERNAME" --dest-password="$DAGGER_REGISTRY_PASSWORD" docker://docker.io/library/alpine:latest docker://git.localhost:8443/aruba-demo/my-nginx-1:latest
# skopeo copy --override-os=linux --dest-tls-verify=false --dest-username="$DAGGER_REGISTRY_USERNAME" --dest-password="$DAGGER_REGISTRY_PASSWORD" docker://quay.io/buildah/stable docker://git.localhost:8443/aruba-demo/my-buildah:latest

# Try to pull the image
docker pull git.localhost:8443/aruba-demo/my-nginx-1:latest
# docker pull git.localhost:8443/aruba-demo/my-buildah:latest

# Check in the browser
open https://git.localhost:8443/aruba-demo/-/packages

# Logout
docker logout git.localhost:8443

# Try to push
docker tag git.localhost:8443/aruba-demo/my-nginx-1:latest git.localhost:8443/aruba-demo/my-nginx-1:v1
docker push git.localhost:8443/aruba-demo/my-nginx-1:v1

# Docker login
echo ${DAGGER_REGISTRY_PASSWORD} | docker login git.localhost:8443 --username ${DAGGER_REGISTRY_USERNAME} --password-stdin

# Try to push
export DOCKER_TLS_VERIFY=0
docker push git.localhost:8443/aruba-demo/my-nginx-1:v1

```
