#!/bin/bash -vx

export SSH_USER="ubuntu"
export MC_DIR="/minecraft"
export MC_ZIP_PATH="$${MC_DIR}/bedrock-server.zip"

install_minecraft_server() {
  WGET=$(which wget)
  DPKG=$(which dpkg)

  # install older version of libssl required for bedrock server
  $WGET http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb -O $${MC_DIR}/libssl1.1.deb
  $DPKG -i $${MC_DIR}/libssl1.1.deb
  rm $${MC_DIR}/libssl1.1.deb

  # get bedock url
  DOWNLOAD_URL=$(curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -s -L -A "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)" https://minecraft.net/en-us/download/server/bedrock/ |  grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*')

  # download it to our local MC dir
  $WGET $${DOWNLOAD_URL} -O $${MC_ZIP_PATH}

  # extract zip
  unzip $${MC_ZIP_PATH} -d $${MC_DIR}/
}

#
# Configure OS
#

export DEBIAN_FRONTEND=noninteractive

# config apt
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-2 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-2 seen true | debconf-set-selections

# install packages
/usr/bin/apt-get update
/usr/bin/apt-get -yq install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" curl wget unzip grep screen openssl awscli jq

/bin/cat <<HERE_DOC > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
HERE_DOC

# Create update Script
cat <<HERE_DOC > $MC_DIR/update.sh
#!/bin/bash

set -e

# stop minecraft
/etc/init.d/minecraft stop

# get bedock url
DOWNLOAD_URL=\$(curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -s -L -A "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)" https://minecraft.net/en-us/download/server/bedrock/ |  grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*')

# remove existing zip if exists
rm -rf $${MC_ZIP_PATH}

# remove existing exec if exists
rm -rf $${MC_DIR}/bedrock_server

# download it to our local MC dir
wget \$DOWNLOAD_URL -O $${MC_ZIP_PATH}

# extract zip
unzip -nq $${MC_ZIP_PATH} -d $${MC_DIR}/

# update user permissions
/bin/chown -R $SSH_USER:$SSH_USER $${MC_DIR}

# start minecraft
/etc/init.d/minecraft start

HERE_DOC

# Make update script executable
/bin/chmod +x $MC_DIR/update.sh

# Init script for starting, stopping
cat <<HERE_DOC > /etc/init.d/minecraft
#!/bin/bash
# Short-Description: Minecraft server

start() {
  echo "Starting minecraft server from $${MC_DIR}..."
  LD_LIBRARY_PATH=. start-stop-daemon --start --quiet  --pidfile $${MC_DIR}/minecraft.pid -m -b -c $SSH_USER -d $${MC_DIR} --exec bedrock_server
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
# To force a new server version, remove the installer from s3
if [[ ! -e "$${MC_ZIP_PATH}" ]]; then
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
