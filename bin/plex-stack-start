#!/bin/bash

# get all container names from docker-compose.yml
IFS=' ' read -r -a CONTAINERS <<< $(grep container_name docker-compose.yml | cut -d ':' -f2 | xargs)

# get variables from .env
export $(grep -v '^#' .env | xargs -d '\n')

# set plexdrive data path which will be used for checking if it is ready
PLEXDRIVE_PATH=./plexdrive/unionfs/

# set the docker-compose project name
PROJECT=$COMPOSE_PROJECT_NAME

# create docker network if it does not exist
docker network inspect ${PROJECT} >/dev/null 2>&1 || docker network create ${PROJECT}

# create encfs volume, create if it does not exist and copy encfs config files
docker volume inspect ${PROJECT}_encfs >/dev/null 2>&1 || docker volume create ${PROJECT}_encfs
./bin/docker-volume-cp ./encfs/. ${PROJECT}_encfs:.

# create docker volumes for containers if they do not exist and copy config files
for CONTAINER in "${CONTAINERS[@]}"
do
  case $CONTAINER in
    traefik)
      docker volume inspect ${PROJECT}_$CONTAINER >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER
      cp ./$CONTAINER/dynamic_conf.toml.example ./$CONTAINER/dynamic_conf.toml
      sed -i "s|HTPASSWD|$HTPASSWD|g" ./$CONTAINER/dynamic_conf.toml
      sed -i "s|DOMAIN|$DOMAIN|g" ./$CONTAINER/dynamic_conf.toml
      cp ./$CONTAINER/traefik.toml.example ./$CONTAINER/traefik.toml
      sed -i "s|ACME_EMAIL|$ACME_EMAIL|g" ./$CONTAINER/traefik.toml
      ./bin/docker-volume-cp ./$CONTAINER/. ${PROJECT}_$CONTAINER:.
      rm ./$CONTAINER/dynamic_conf.toml
      rm ./$CONTAINER/traefik.toml
      ;;
    rclone)
      docker volume inspect ${PROJECT}_$CONTAINER-logs >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-logs
      docker volume inspect ${PROJECT}_$CONTAINER-config >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-config
      ./bin/docker-volume-cp ./$CONTAINER/. ${PROJECT}_$CONTAINER-config:.
      ;;
    plex)
      docker volume inspect ${PROJECT}_$CONTAINER-config >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-config
      docker volume inspect ${PROJECT}_$CONTAINER-transcode >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-transcode
      ;;
    sabnzbd)
      docker volume inspect ${PROJECT}_$CONTAINER-config >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-config
      docker volume inspect ${PROJECT}_$CONTAINER-downloads >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-downloads
      docker volume inspect ${PROJECT}_$CONTAINER-incomplete >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-incomplete
      ;;
    deluge|\
    jackett)
      docker volume inspect ${PROJECT}_$CONTAINER-config >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-config
      docker volume inspect ${PROJECT}_$CONTAINER-downloads >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER-downloads
      ;;
    portainer|\
    tautulli|\
    ombi|\
    sonarr|\
    organizr|\
    rclone|\
    radarr|\
    lidarr|\
    plexdrive)
      docker volume inspect ${PROJECT}_$CONTAINER >/dev/null 2>&1 || docker volume create ${PROJECT}_$CONTAINER
      ;;
  esac

  if [ ! $CONTAINER = "plex" ] && \
     [ ! $CONTAINER = "sonarr" ] && \
     [ ! $CONTAINER = "radarr" ] && \
     [ ! $CONTAINER = "lidarr" ] && \
     [ ! $CONTAINER = "rclone" ]; then
    docker-compose up -d $CONTAINER
  fi
done

# while the plexdrive /unionfs mount is inaccessible, sleep
while [ ! "$(ls -A $PLEXDRIVE_PATH)" ]
do
  printf "waiting for $PLEXDRIVE_PATH to mount\n"
  sleep 2
done

for CONTAINER in "${CONTAINERS[@]}"
do
  docker-compose up -d $CONTAINER
done
