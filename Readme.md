# Dagger: publish to a (k3d) local registry

## Reference

- Custom CA
  - <https://docs.dagger.io/manuals/administrator/custom-ca/>

## Run with Docker Compose

```sh
docker compose --profile full up
```

## Modify the dagger engine runner, connecting it to the host network (instead of the bridge)

```sh
# Set engine name
export DAGGER_ENGINE='dagger-engine-v0.13.3'

# stop and remove the dagger runner
docker stop ${DAGGER_ENGINE} ; docker rm ${DAGGER_ENGINE}

# dump the config
docker inspect ${DAGGER_ENGINE} > dagger_inspect.json

# pass the config to chatgpt and ask to keep all the config but replace the network with the host one

# Set custom engine name
export DAGGER_ENGINE_CUSTOM="dagger-engine-custom"
export DAGGER_ENGINE_IMAGE="registry.dagger.io/engine:v0.13.3"

# 🇦🇽 or, with an anonymous volume, just like the original
docker run -d \
  --name ${DAGGER_ENGINE_CUSTOM} \
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
  --debug

# Other options for the volume mount
  # -v 124af10e4361f7a7e3b8a0c24342aedce87f07928266010acc87e1b01cd0a39a:/var/lib/dagger \
  # -v dagger-engine:/var/lib/dagger \


# Set the runner to the custom dagger engine
export _EXPERIMENTAL_DAGGER_RUNNER_HOST="docker-container://${DAGGER_ENGINE_CUSTOM}"

# try again the publish from
#   ⋯/_projects/Aruba-DevOps/fastapi-demo
dagger call publish-local --srv=tcp://localhost:5000
# this time it works! 🎉

# Check the image is present on the registry
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
