#1 /bin/bash

# Clone repo do Docker
git clone https://github.com/mixeme/chatmail-relay-docker.git /opt/chatmail-relay-docker
cd /opt/chatmail-relay-docker

# Clone main repo
git clone https://github.com/chatmail/relay.git ./chatmail

#
docker compose up -d --build
docker compose exec chatmail ./scripts/initenv.sh
docker compose exec chatmail ./scripts/cmdeploy init 4vps.mixdep.ru
docker compose exec chatmail ./scripts/cmdeploy run --ssh-host localhost
#docker compose exec chatmail ./scripts/cmdeploy dns --ssh-host localhost
#docker compose down && docker compose up -d
