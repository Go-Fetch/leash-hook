# To use:
# curl -k https://raw.githubusercontent.com/Go-Fetch/leash-hook/master/create-installer-zone.sh | bash -s "10.10.10.10" "10.10.10.1" "255.255.255.0"
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
wget --no-check-certificate -O /opt/zone_definitions/installer_zone.json.tmp https://raw.githubusercontent.com/Go-Fetch/leash-hook/master/create-zone-def.template?$RANDOM

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

zlogin -i $VMUUID "curl -k https://raw.githubusercontent.com/Go-Fetch/leash-hook/master/prep-installer-zone.sh?$RANDOM | /bin/bash"

imgadm create -c bzip2 $VMUUID name=fifo-installer version=0.6.1-2 -o /var/tmp
