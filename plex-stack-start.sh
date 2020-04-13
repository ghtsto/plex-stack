#!/bin/bash

# get all container names from docker-compose.yml
IFS=' ' read -r -a containers <<< $(grep container_name docker-compose.yml | cut -d ':' -f2 | xargs)

# set plexdrive data path which will be used for checking if it is ready
PLEXDRIVE_PATH=$(grep DATA_DIR .env | cut -d '=' -f2)/plexdrive/data/

# start every container except plex, sonarr, radarr, lidarr or rclone as they depend on the plexdrive /data mount
for container in "${containers[@]}"
do
  if [ ! "$container" = "plex" ] && [ ! "$container" = "sonarr" ] && [ ! "$container" = "radarr" ] && [ ! "$container" = "lidarr" ] && [ ! "$container" = "rclone" ]; then
    docker-compose up -d "$container"
  fi
done

# while the plexdrive /data mount is inaccessible, sleep
while [ ! "$(ls -A $PLEXDRIVE_PATH)" ]
do
  printf "waiting for $PLEXDRIVE_PATH to mount\n"
  sleep 2
done

# after plexdrive /data mount is accessible, bring remaining containers up
docker-compose up -d plex
docker-compose up -d sonarr
docker-compose up -d radarr
docker-compose up -d lidarr
docker-compose up -d rclone
