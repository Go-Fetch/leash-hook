# To use:
# curl -k https://raw.githubusercontent.com/Go-Fetch/leash-hook/master/fifo-install.sh | bash -s "10.10.10.10" "10.10.10.1" "255.255.255.0"
# or
# curl -k https://raw.githubusercontent.com/Go-Fetch/leash-hook/master/fifo-install.sh | bash -s "dhcp"
#
InstallerZoneIP=$(echo $1 | tr '[:lower:]' '[:upper:]')
InstallerZoneGW=$2
InstallerZoneMASK=$3

RANDOM=`awk 'BEGIN{srand();print int(rand()*(63000-2000))+2000 }'` #Used to break cache

BASE="https://us-east.manta.joyent.com/kevinmeziere/public/fifo-install/"
REV="0.6.1-6"
IMAGE="c8bbc300-7534-499b-b49b-33f0efa1b2a3"


mkdir /opt/images
mkdir /opt/zone_definitions
wget --no-check-certificate -O /opt/images/fifo-installer-"${REV}".dsmanifest "${BASE}"fifo-installer-"${REV}".imgmanifest
wget --no-check-certificate -O /opt/images/fifo-installer-"${REV}".zfs.bz2 "${BASE}"fifo-installer-"${REV}".zfs.bz2
imgadm install -m /opt/images/fifo-installer-"${REV}".dsmanifest -f /opt/images/fifo-installer-"${REV}".zfs.bz2
wget --no-check-certificate -O /opt/zone_definitions/installer-zone-def.template https://raw.githubusercontent.com/Go-Fetch/leash-hook/master/installer-zone-def.template?$RANDOM

if [ "$InstallerZoneIP" = "DHCP" ]
then
  sed "s/{{IMGUUID}}/$IMAGE/g;s/{{IP}}/dhcp/g;/{{GW}}/d;/{{MASK}}/d" /opt/zone_definitions/installer-zone-def.template > /opt/zone_definitions/installer-zone-def.json
else
  sed "s/{{IMGUUID}}/$IMAGE/g;s/{{IP}}/$InstallerZoneIP/g;s/{{GW}}/$InstallerZoneGW/g;s/{{MASK}}/$InstallerZoneMASK/g" /opt/zone_definitions/installer-zone-def.template > /opt/zone_definitions/installer-zone-def.json
fi

echo "Creating temporary vm for installation..."

VMUUID=$((vmadm create -f /opt/zone_definitions/installer-zone-def.json) 2>&1 | grep "Successfully" | awk '{print $4}')
if [ -z "$VMUUID" ]
then
	echo "Unable to create installer VM."
	exit 1
fi

echo "Successfully created installation VM: $VMUUID"
echo "Prepping zone to run installer."


HyperIP=$(ifconfig | grep inet | grep -v '127.0.0.1' | grep -v '\:\:1/128' | awk '{print $2}' | head -n 1)
HyperGW=$(netstat -rn | grep default | awk '{print $2}')
HyperMASK=$(ifconfig | grep inet | grep -v '127.0.0.1' | grep -v '\:\:1/128' | awk '{print $4}' | head -n 1 | sed -r 's/(..)/0x\1 /g' | xargs printf '%d.%d.%d.%d\n')


mkdir /zones/$VMUUID/root/opt/local/leash/config
echo $HyperGW > /zones/$VMUUID/root/opt/local/leash/config/host.gateway
echo $HyperIP > /zones/$VMUUID/root/opt/local/leash/config/host.ip
echo $HyperMASK > /zones/$VMUUID/root/opt/local/leash/config/host.netmask

zlogin -Qi $VMUUID "/opt/local/leash/info.sh"
