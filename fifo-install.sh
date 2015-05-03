# To use:
# curl -k http://s3.amazonaws.com/tmp.jpcu/fi/install | bash -s "10.10.10.10" "10.10.10.1" "255.255.255.0"
#
#if [ $(uname -a | egrep 20150108T111855Z | wc -l) -eq 1 ]; then echo "ok"; fi
#
InstallerZoneIP=$(echo $1 | tr '[:lower:]' '[:upper:]')
InstallerZoneGW=$2
InstallerZoneMASK=$3


imgadm update
mkdir /opt/images
mkdir /opt/zone_definitions
imgadm import 5a4ba06a-c1bb-11e4-af0b-4be0ce4ce04c
#wget --no-check-certificate -O /opt/images/minimal-64-lts-14.4.0.dsmanifest https://datasets.joyent.com/datasets/5a4ba06a-c1bb-11e4-af0b-4be0ce4ce04c
#wget --no-check-certificate -O /opt/images/minimal-64-lts-14.4.0.zfs.gz https://datasets.joyent.com/datasets/5a4ba06a-c1bb-11e4-af0b-4be0ce4ce04c/minimal-64-lts-14.4.0.zfs.gz
#imgadm install -m /opt/images/minimal-64-lts-14.4.0.dsmanifest  -f /opt/images/minimal-64-lts-14.4.0.zfs.gz
wget --no-check-certificate -O /opt/zone_definitions/installer_zone.json.tmp https://tmp.jpcu.s3.amazonaws.com/fi/installer_zone.json

if [ "$InstallerZoneIP" = "DHCP" ]
then
  sed "s/{{IP}}/dhcp/g;/{{GW}}/d;/{{MASK}}/d" /opt/zone_definitions/installer_zone.json.tmp > /opt/zone_definitions/installer_zone.json
else
  sed "s/{{IP}}/$InstallerZoneIP/g;s/{{GW}}/$InstallerZoneGW/g;s/{{MASK}}/$InstallerZoneMASK/g" /opt/zone_definitions/installer_zone.json.tmp > /opt/zone_definitions/installer_zone.json
fi

echo "Creating temporary vm for installation..."

VMUUID=$((vmadm create -f /opt/zone_definitions/installer_zone.json) 2>&1 | grep "Successfully" | awk '{print $4}')
if [ -z "$VMUUID" ]
then
	echo "Unable to create installer VM."
	exit 1
fi

echo "Successfully created installation VM: $VMUUID"
echo "Prepping zone to run installer."

zlogin -i $VMUUID "curl -k http://s3.amazonaws.com/tmp.jpcu/fi/prep_zone.sh | /bin/bash"

imgadm create -c bzip2 9134589c-dbff-4a0a-b0ea-10f77fa7e46b name=fifo-installer version=0.6.1-1 -o /var/tmp

IP=`ifconfig | grep inet | grep -v '127.0.0.1' | grep -v '\:\:1/128' | awk '{print $2}' | head -n 1`
GW=`netstat -rn | grep default | awk '{print $2}'`
MASK=`ifconfig | grep inet | grep -v '127.0.0.1' | grep -v '\:\:1/128' | awk '{print $4}' | head -n 1 | sed -r 's/(..)/0x\1 /g' | xargs printf '%d.%d.%d.%d\n'`
