pkgin up
pkgin -y in python27-2.7.9 py27-pip-1.5.6 sshpass-1.05 git-2.2.1

pip install fabric==1.10.1
pip install ansible==1.9.1
pip install flask==0.10.1
pip install twisted==15.1.0
pip install autobahn==0.10.3
pip install PyFi==0.2.3

cd /opt/local
git clone --depth 1 https://github.com/Go-Fetch/Fetch.git fetch
 
cd /opt/local/fetch
git submodule update --depth 1 --init --recursive


cat >/opt/local/fetch/fifo-sniffle.yml  <<EOL
- hosts: fifo-sniffle-nodes
  roles:
    - fifo-sniffle
EOL

cat >/opt/local/fetch/fifo-snarl.yml  <<EOL
- hosts: fifo-snarl-nodes
  roles:
    - fifo-snarl
EOL

cat >/opt/local/fetch/fifo-howl.yml  <<EOL
- hosts: fifo-howl-nodes
  roles:
    - fifo-howl
EOL

cat >/opt/local/fetch/fifo-jingles.yml <<EOL
- hosts: fifo-jingles-nodes
  roles:
    - fifo-jingles
EOL

cat >/opt/local/fetch/leofs-manager.yml <<EOL
- hosts: leofs-manager-nodes
  roles:
    - leofs-manager
EOL

cat >/opt/local/fetch/leofs-gateway.yml <<EOL
- hosts: leofs-gateway-nodes
  roles:
    - leofs-gateway
EOL

cat >/opt/local/fetch/leofs-storage.yml <<EOL
- hosts: leofs-storage-nodes
  roles:
    - leofs-storage
EOL

cat>/opt/local/fetch/hypervisors.yml <<EOL
- hosts: hypervisors
  gather_facts: no
  roles:
    - hypervisor
    - fifo-chunter
EOL


cd /opt/local
git clone https://github.com/Go-Fetch/leash.git leash

groupadd leash
useradd -g leash -d /opt/local/leash -s /bin/false leash

mkdir /leash
chown leash:leash /leash

mkdir /var/log/leash
chown -R leash:leash /var/log/leash

chown -R leash:leash /opt/local/leash
chown -R leash:leash /opt/local/fetch
chmod +x /opt/local/leash/leash
chmod +x /opt/local/leash/log-socket
chmod +x /opt/local/leash/info.sh

svccfg import /opt/local/leash/leash.xml
svccfg import /opt/local/leash/log-socket.xml

svcadm enable leash
svcadm enable log-socket


pkgin -y remove build-essential-1.1 gmake-4.1nb1 automake-1.14.1nb1 bison-3.0.2nb1 git-docs-2.2.1 patch-2.7.4 git-base-2.2.1 gcc47-4.7.3nb6 libtool-2.4.2nb2 libtool-fortran-2.4.2nb5 binutils-2.24nb3 m4-1.4.17 libtool-info-2.4.2 p5-Authen-SASL-2.16nb2 autoconf-2.69nb5 curl-7.42.0 libtool-base-2.4.2nb9 p5-Net-SMTP-SSL-1.01nb5 p5-Error-0.17022 p5-Email-Valid-1.195 p5-MailTools-2.14 p5-TimeDate-2.30nb1 p5-IO-Socket-SSL-2.007 p5-Net-DNS-0.81 p5-Digest-HMAC-1.03nb4 p5-Net-Domain-TLD-1.72 p5-IO-CaptureOutput-1.11.03 p5-GSSAPI-0.28nb5 libssh2-1.4.3 openldap-client-2.4.40 libidn-1.29 p5-Net-LibIDN-0.12nb6 cyrus-sasl-2.1.26nb4 p5-Net-SSLeay-1.66 mit-krb5-1.10.7nb4 p5-IO-Socket-INET6-2.72 p5-Socket6-0.25 p5-Net-IP-1.26nb2 tcp_wrappers-7.6.4
pkgin -y clean
pkgin -y in openssh-6.6.1nb3
sm-prepare-image -y
