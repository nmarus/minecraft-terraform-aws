#!/bin/bash -vx

export SSH_USER="ubuntu"
export MC_DIR="/minecraft"
export MINECRAFT_JAR="minecraft_server.jar"

# Use the Mojang version_manifest.json to find java download location
# See https://minecraft.gamepedia.com/Version_manifest.json
install_minecraft_server() {
  WGET=$(which wget)

  # version_manifest.json lists available MC versions
  $WGET -O $${MC_DIR}/version_manifest.json https://launchermeta.mojang.com/mc/game/version_manifest.json

  # Find latest version number if user wants that version (the default)
  if [[ "${mc_version}" == "latest" ]]; then
    MC_VERS=$(jq -r '.["latest"]["'"${mc_type}"'"]' $${MC_DIR}/version_manifest.json)
  fi

  # Index version_manifest.json by the version number and extract URL for the specific version manifest
  VERSIONS_URL=$(jq -r '.["versions"][] | select(.id == "'"$MC_VERS"'") | .url' $${MC_DIR}/version_manifest.json)
  # From specific version manifest extract the server JAR URL
  SERVER_URL=$(curl -s $VERSIONS_URL | jq -r '.downloads | .server | .url')
  # And finally download it to our local MC dir
  $WGET -O $${MC_DIR}/$MINECRAFT_JAR $SERVER_URL
}

#
# Configure OS
#

export DEBIAN_FRONTEND=noninteractive

echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-2 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-2 seen true | debconf-set-selections

/usr/bin/apt-get update
/usr/bin/add-apt-repository -y ppa:linuxuprising/java
/usr/bin/apt-get update
/usr/bin/apt-get -yq install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" openjdk-16-jdk wget awscli jq

/bin/cat <<HERE_DOC > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
HERE_DOC

# Init script for starting, stopping
cat <<HERE_DOC > /etc/init.d/minecraft
#!/bin/bash
# Short-Description: Minecraft server

start() {
  echo "Starting minecraft server from $${MC_DIR}..."
  start-stop-daemon --start --quiet  --pidfile $${MC_DIR}/minecraft.pid -m -b -c $SSH_USER -d $${MC_DIR} --exec /usr/bin/java -- -Xmx${java_mx_mem} -Xms${java_ms_mem} -jar $MINECRAFT_JAR nogui
}

stop() {
  echo "Stopping minecraft server..."
  start-stop-daemon --stop --pidfile $${MC_DIR}/minecraft.pid
}

case \$1 in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    sleep 5
    start
    ;;
esac
exit 0
HERE_DOC

# Start up on reboot
/bin/chmod +x /etc/init.d/minecraft
/usr/sbin/update-rc.d minecraft defaults

#
# Configure S3 Backup
#

/bin/mkdir -p $${MC_DIR}
/usr/bin/aws s3 sync s3://${mc_bucket} $${MC_DIR}

# Download and install server if it doesn't exist on S3 already (existing from previous install)
# To force a new server version, remove the server JAR from S3 bucket
if [[ ! -e "$${MC_DIR}/$MINECRAFT_JAR" ]]; then
  install_minecraft_server
fi

# Cron job to sync data to S3
/bin/cat <<HERE_DOC > /etc/cron.d/minecraft
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$${MC_DIR}
*/${mc_backup_freq} * * * *  $SSH_USER  /usr/bin/aws s3 sync $${MC_DIR}  s3://${mc_bucket}
HERE_DOC

#
# Configure Minecraft
#

# Update minecraft EULA
/bin/cat >$${MC_DIR}/eula.txt<<HERE_DOC
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula).
#Tue Jan 27 21:40:00 UTC 2015
eula=true
HERE_DOC

# configure server.properties
/bin/cat >$${MC_DIR}/server.properties<<HERE_DOC
${server_properties}
HERE_DOC

# update user permissions
/bin/chown -R $SSH_USER:$SSH_USER $${MC_DIR}

#
# Start
#

/etc/init.d/minecraft start

exit 0
