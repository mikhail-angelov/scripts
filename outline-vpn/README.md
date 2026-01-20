# Outline-VPN-docker

Repository (https://github.com/DiffuseHyperion/outline-vpn-docker) containing a multi-platform shadowbox docker image to run in a generic docker-compose.yml file.

Available on Dockerhub: https://hub.docker.com/r/diffusehyperion/outline-vpn

## Usage
1. Run via docker compose `docker-compose.yml`.

2. Create an access key with `docker exec shadowbox /app/create-key`.

3. Copy the given URL into your Outline Client.

There are also other scripts to help manage keys:
- `/app/list-keys` shows all access keys and their corresponding ID.
- `/app/delete-key <id>` deletes the access key with the ID provided.
- `/app/show-key <id>` shows the connection URL of the access key with the ID provided.