# plex-stack

Deploy plex and media automation utilities, backed by google drive for storage and using traefik as a reverse proxy.

## Prerequisites
* `docker`
* `docker-compose`
* [CloudFlare](https://www.cloudflare.com) free-tier account

## Prepare
#### docker 
https://docs.docker.com/get-started/

#### docker-compose
https://docs.docker.com/compose/install/

#### CloudFlare
Configure your domain name in CloudFlare as DNS-only

#### Host
Ubuntu 18.04 is the assumed host operating system

## Setup
### Configure Environment Variables
Create and edit `.env`
```shell
cp .env.example .env
```
Edit ```.env``` and add values to the environment variables
* `PUID` - set to the uid of your user (```id $user```)
* `PGID` - set to the gid of your user (```id $user```)
* `TZ` - set your timezone (```timedatectl```)
* `DOMAIN` - the root domain configured with CloudFlare DNS
* `COMPOSE_PROJECT_NAME` - used as network name and prepended to volume names
* `PLEXDRIVE_OPTS` - additional options for plexdrive (see [usage](https://github.com/plexdrive/plexdrive/#usage))
* `CLOUDFLARE_EMAIL` - the email address used for your CloudFlare account
* `CLOUDFLARE_API_KEY` - the global API key from your CloudFlare profile
* `ACME_EMAIL` - the email you will use for registering HTTPS cert with [Let's Encrypt](https://letsencrypt.org/)
* `HTPASSWD` - auth used for securing traefik dashboard (install ```apache2-utils``` then ```htpasswd -n username```)
* `PLEX_CLAIM` - plex claim [token](https://www.plex.tv/claim/) (add this when ready to deploy as token expires in minutes)

### Prepare encfs settings
Copy your existing ```encfs.xml``` (XML encryption data) and ```encfspass``` (file containing encryption password) to ```./encfs/```. On initialization, these files will be copied to a docker volume which is used with the plexdrive and rclone containers for encrypting/decrypting files

If you are setting this up for the first time, you can generate new ```encfs.xml``` and ```encfspass``` files after updating the ```ENCFS_PASS``` value and running the following command. You may update the mount source directory to ```${PWD}/encfs``` to place the files directly into the required directory but note that it will overwite any existing files.
```shell
docker run -it --rm \
    --privileged \
    --device /dev/fuse \
    --env ENCFS_PASS=password \
    --mount type=bind,src=${PWD},dst=/encfs \
    ghtsto/encfs:latest \
    generate-encfs &>/dev/null
```
Move the generated files into ```./encfs/``` if required

### Firewall
Allow ports 80 and 443 for traefik and 58946 for deluge seeding.
```shell
ufw allow 80
ufw allow 443
ufw allow 58946
```

### Initialize plex-stack
The start script ```./bin/plex-stack-start``` can be used for the initial creation of the network, volumes, containers and adding config files to volumes. The script will wait for the ```./plexdrive/unionfs/``` mount to be accessible before starting containers which depend on it.

### Configure plexdrive (media mount)
Once the plexdrive container is running, configure plexdrive with google drive:
```shell
docker-compose exec plexdrive plexdrive_setup
```
After enting your API token, the shell will hang. Press CTRL+C to proceed.

If start script is still running, it should now detect the ```./plexdrive/unionfs/``` mount and start the remaining containers.

### Configure rclone (upload and cleanup)
After rclone is up and running, setup google drive config (use the name "gdrive" during setup):
```shell
docker-compose exec rclone rclone_setup
```
By default, files at least 8 hours old are uploaded to google drive when the upload script runs.

Upload and cleanup scripts will run daily at 02:00, based on the timezone configured in ```.env```. See directories and scripts in ```./rclone/cron/```.

You can manually trigger the upload and cleanup tasks by running the following:
```shell
docker-compose exec rclone rclone_upload
docker-compose exec rclone rclone_cleanup
```
Run ```docker-compose exec rclone rclone_upload now``` to upload all local files, regardless of their age.

### Finished
List running containers:
```shell
docker ps
```
If all went well, the containers should be running and accessible at the subdomains shown in the docker traefik "rule" label in the compose file for each container (eg. traefik.yourdomain.com).

**Ensure you navigate to each running container sub-domain in order to configure and secure each service.**

Once all is up and running, you may use the ```./bin/plex-stack-start``` script to start all containers. Use the systemd unit file from the ```./systemd/``` directory as a way to start the stack after system reboot.

#### Sources
- plex media server ([github](https://github.com/plexinc/pms-docker) / [docker](https://hub.docker.com/r/plexinc/pms-docker))
- plexdrive ([github](https://github.com/plexdrive/plexdrive) / [docker](https://hub.docker.com/r/ghtsto/plexdrive-encfs))
- rclone ([github](https://github.com/rclone/rclone) / [docker](https://hub.docker.com/r/ghtsto/rclone-encfs-cron))
- sonarr ([github](https://github.com/Sonarr/Sonarr) / [docker](https://hub.docker.com/r/linuxserver/sonarr))
- radarr ([github](https://github.com/Radarr/Radarr) / [docker](https://hub.docker.com/r/linuxserver/radarr))
- lidarr ([github](https://github.com/lidarr/Lidarr) / [docker](https://hub.docker.com/r/linuxserver/lidarr))
- sabnzbd ([github](https://github.com/sabnzbd/sabnzbd) / [docker](https://hub.docker.com/r/linuxserver/sabnzbd))
- deluge ([github](https://github.com/deluge-torrent/deluge) / [docker](https://hub.docker.com/r/linuxserver/deluge))
- jackett ([github](https://github.com/Jackett/Jackett) / [docker](https://hub.docker.com/r/linuxserver/jackett))
- tautulli ([github](https://github.com/Tautulli/Tautulli) / [docker](https://hub.docker.com/r/tautulli/tautulli))
- organizr ([github](https://github.com/causefx/Organizr) / [docker](https://hub.docker.com/r/organizrtools/organizr-v2))
- ombi ([github](https://github.com/tidusjar/Ombi) / [docker](https://hub.docker.com/r/linuxserver/ombi))
- portainer ([github](https://github.com/portainer/portainer) / [docker](https://hub.docker.com/r/portainer/portainer))
- watchtower ([github](https://github.com/containrrr/watchtower) / [docker](https://hub.docker.com/r/containrrr/watchtower))
- traefik ([github](https://github.com/containous/traefik) / [docker](https://hub.docker.com/_/traefik))
