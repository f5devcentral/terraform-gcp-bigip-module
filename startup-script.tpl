#!/bin/bash

source /usr/lib/bigstart/bigip-ready-functions

mkdir -p  /var/log/cloud /config/cloud /var/config/rest/downloads

LOG_FILE=/var/log/cloud/startup-script.log
[[ ! -f $LOG_FILE ]] && touch $LOG_FILE || { echo "Run Only Once. Exiting"; exit; }
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1


mkdir -p /config/cloud

mkdir -p /var/lib/cloud/icontrollx_installs

cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters:
  - name: USER_NAME
    type: static
    value: ${bigip_username}
  - name: SSH_KEYS
    type: static
    value: "${ssh_keypair}"
EOF

if ${gcp_secret_manager_authentication}
then
   cat << 'EOF' >> /config/cloud/runtime-init-conf.yaml
  - name: ADMIN_PASS
    type: secret
    secretProvider:
      environment: gcp
      type: SecretsManager
      version: latest
      secretId: ${bigip_password}
EOF
else
   cat << 'EOF' >> /config/cloud/runtime-init-conf.yaml
  - name: ADMIN_PASS
    type: static
    value: ${bigip_password}
EOF
fi


cat << 'EOF' >> /config/cloud/runtime-init-conf.yaml
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 1024
      - /usr/bin/setdb restjavad.useextramb true
extension_packages: 
  install_operations:
    - extensionType: do
      extensionVersion: ${DO_VER}
      extensionUrl: ${DO_URL}
    - extensionType: as3
      extensionVersion: ${AS3_VER}
      extensionUrl: ${AS3_URL}
    - extensionType: ts
      extensionVersion: ${TS_VER}
      extensionUrl: ${TS_URL}
    - extensionType: cf
      extensionVersion: ${CFE_VER}
      extensionUrl: ${CFE_URL}
    - extensionType: fast
      extensionVersion: ${FAST_VER}
      extensionUrl: ${FAST_URL}
extension_services: 
  service_operations:
    - extensionType: do
      type: url
      value: https://raw.githubusercontent.com/f5devcentral/terraform-gcp-bigip-module/master/config/onboard_do.json
EOF

#PACKAGE_URL='https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.1.0/dist/f5-bigip-runtime-init-1.1.0-1.gz.run'
for i in {1..30}; do
curl -fv --retry 1 --connect-timeout 5 -L ${INIT_URL} -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
done


# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init.gz.run -- '--cloud gcp'

/usr/local/bin/f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml

COMPUTE_BASE_URL="http://metadata.google.internal/computeMetadata/v1"

if ${NIC_COUNT}
then
   cat << 'EOF' >> /config/cloud/nic_swap.sh
   #!/bin/bash
   source /usr/lib/bigstart/bigip-ready-functions
   echo "before nic swapping"
   tmsh list sys db provision.1nicautoconfig
   tmsh list sys db provision.managementeth
   echo "after nic swapping"
   bigstart stop tmm
   tmsh modify sys db provision.managementeth value eth1
   tmsh modify sys db provision.1nicautoconfig value disable
   bigstart start tmm
   wait_bigip_ready
   echo "---Mgmt interface setting---"
   tmsh list sys db provision.managementeth
   tmsh list sys db provision.1nicautoconfig
   sed -i "s/iface0=eth0/iface0=eth1/g" /etc/ts/common/image.cfg
   echo "Done changing interface"
   echo "Set TMM networks"
   MGMTADDRESS=$(curl -s -f --retry 10 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/ip)
   MGMTMASK=$(curl -s -f --retry 10 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/subnetmask)
   MGMTGATEWAY=$(curl -s -f --retry 10 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/gateway)
   MGMTMTU=$(curl -s -f --retry 10 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/1/mtu)
   MGMTNETWORK=$(/bin/ipcalc -n $MGMTADDRESS $MGMTMASK | cut -d= -f2)
   echo $MGMTADDRESS
   echo $MGMTMASK
   echo $MGMTGATEWAY
   echo $MGMTMTU
   echo $MGMTNETWORK   
   tmsh modify sys global-settings gui-setup disabled
   tmsh modify sys global-settings mgmt-dhcp disabled
   tmsh delete sys management-route all 
   tmsh delete sys management-ip all
   tmsh create sys management-ip $${MGMTADDRESS}/32
   tmsh create sys management-route mgmt_gw network $${MGMTGATEWAY}/32 type interface mtu $${MGMTMTU}
   tmsh create sys management-route mgmt_net network $${MGMTNETWORK}/$${MGMTMASK} gateway $${MGMTGATEWAY} mtu $${MGMTMTU}
   tmsh create sys management-route default gateway $${MGMTGATEWAY} mtu $${MGMTMTU}
   tmsh modify sys global-settings remote-host add { metadata.google.internal { hostname metadata.google.internal addr 169.254.169.254 } }
   tmsh modify sys management-dhcp sys-mgmt-dhcp-config request-options delete { ntp-servers }
   tmsh save /sys config
   reboot
EOF
fi

if ${NIC_COUNT}
then
   chmod +x /config/cloud/nic_swap.sh
   /config/cloud/nic_swap.sh >> $LOG_FILE
fi
