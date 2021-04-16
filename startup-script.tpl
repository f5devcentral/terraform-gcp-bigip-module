#!/bin/bash

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

curl -o /config/cloud/do_w_admin.json -s --fail --retry 60 -m 10 -L https://raw.githubusercontent.com/f5devcentral/terraform-azure-bigip-module/dev_saketha_runtimeinit/config/onboard_do.json
mkdir -p /var/lib/cloud/icontrollx_installs

cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters:
  - name: USER_NAME
    type: static
    value: ${bigip_username}
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
      - /usr/bin/setdb provision.extramb 2048
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
extension_services: 
  service_operations:
    - extensionType: do
      type: url
      value: file:///config/cloud/do_w_admin.json
EOF

#PACKAGE_URL='https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.1.0/dist/f5-bigip-runtime-init-1.1.0-1.gz.run'
for i in {1..30}; do
curl -fv --retry 1 --connect-timeout 5 -L ${INIT_URL} -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
done

# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init.gz.run -- '--cloud gcp'

/usr/local/bin/f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml
