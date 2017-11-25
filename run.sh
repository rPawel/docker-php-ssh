#!/bin/bash
KEYGEN="/usr/bin/ssh-keygen"
PERSISTENT_CONFIG_FOLDER="/root/.persistent-config"
PERSISTENT_IGNORED_CONFIG_FOLDER=$PERSISTENT_CONFIG_FOLDER/.ignore
VOLATILE_CONFIG_FOLDER="/"

GLOBAL_SSH_FOLDER="etc/ssh"
ROOT_SSH_FOLDER="root/.ssh"
USER_NAME="user"

generateServerKeys() {
  _KEYGEN=$1
  _GLOBAL_SSH_FOLDER=$2
  mkdir -p ${_GLOBAL_SSH_FOLDER}; chmod 755 ${_GLOBAL_SSH_FOLDER}; chown root: -R ${_GLOBAL_SSH_FOLDER}
  $_KEYGEN -q -t dsa -N "" -f ${_GLOBAL_SSH_FOLDER}/ssh_host_dsa_key
  $_KEYGEN -q -t rsa -N "" -f ${_GLOBAL_SSH_FOLDER}/ssh_host_rsa_key
  $_KEYGEN -q -t ecdsa -N "" -f ${_GLOBAL_SSH_FOLDER}/ssh_host_ecdsa_key
  chmod 600 ${_GLOBAL_SSH_FOLDER}/*
}

generateUserCredentials() {
  _USER_SALT=$(apg -a 1 -n 1 -m 8 -x 8 -q -M ncl)
  _USER_PASSWORD=$(apg -a 1 -n 1 -m 8 -x 8 -q -M ncl)
  echo "USER PASSWORD: "${_USER_PASSWORD}
  _SHADOW_FILE=$1
  perl -e "print crypt(\"${_USER_PASSWORD}\", \"${_USER_SALT}\"),\"\n\"" > ${_SHADOW_FILE}
}

setUserCredentials() {
  _USER_SALT=$(apg -a 1 -n 1 -m 8 -x 8 -q -M ncl)
  _USER_PASSWORD=$2
  echo "USER PASSWORD: "${_USER_PASSWORD}
  _SHADOW_FILE=$1
  perl -e "print crypt(\"${_USER_PASSWORD}\", \"${_USER_SALT}\"),\"\n\"" > ${_SHADOW_FILE}
}

applyUserCredentialsFromShadowFile() {
  _USER_NAME=$1
  _USER_ENC_PASSWORD=$(cat $2)
  echo "$_USER_NAME:$_USER_ENC_PASSWORD" | chpasswd -e
}

generateRootCredentials() {
  _KEYGEN=$1
  _ROOT_SSH_FOLDER=$2
  _ROOT_KEYFILE="$2/$3"
  _AUTH_KEYS="$2/$4"

  mkdir -p ${_ROOT_SSH_FOLDER}; chmod 700 ${_ROOT_SSH_FOLDER}; chown root: -R ${_ROOT_SSH_FOLDER}
  ${_KEYGEN} -q -t rsa -N "" -f ${_ROOT_KEYFILE}
  cat ${_ROOT_KEYFILE}.pub >> ${_AUTH_KEYS}
  chmod 600 ${_AUTH_KEYS}
}

initPersistentConfigFolder() {
  mkdir -p $1; chmod 700 $1
}

configSet() {
    file=$1
    var=$2
    val=$3
    if [ -n "${val}" ]; then
        echo "Setting $var to $val in $file"
        sed -i "s/^\($var\s*\).*$/\1$val/" $file
    fi
}

# runtime setup !
if [ ! -d /var/www/cron ]; then
    mkdir -p /var/www/cron
    chown -R user:www-data /var/www/cron
    chmod 750 /var/www/cron
fi

initPersistentConfigFolder ${PERSISTENT_CONFIG_FOLDER}
initPersistentConfigFolder ${PERSISTENT_IGNORED_CONFIG_FOLDER}

if [ ! -f "$PERSISTENT_CONFIG_FOLDER/$ROOT_SSH_FOLDER/id_rsa" ]; then
    generateRootCredentials ${KEYGEN} "$PERSISTENT_CONFIG_FOLDER/$ROOT_SSH_FOLDER" "id_rsa" "authorized_keys"
fi

if [ "$CTNR_USER_PASSWORD" ]; then
    setUserCredentials "$PERSISTENT_IGNORED_CONFIG_FOLDER/user-shadow" "$CTNR_USER_PASSWORD"
elif [ ! -f "$PERSISTENT_IGNORED_CONFIG_FOLDER/user-shadow" ]; then
    generateUserCredentials "$PERSISTENT_IGNORED_CONFIG_FOLDER/user-shadow"
fi
applyUserCredentialsFromShadowFile ${USER_NAME} "$PERSISTENT_IGNORED_CONFIG_FOLDER/user-shadow"

if [ ! -f "$PERSISTENT_CONFIG_FOLDER/$GLOBAL_SSH_FOLDER/ssh_host_dsa_key" ]; then
    generateServerKeys ${KEYGEN} "$PERSISTENT_CONFIG_FOLDER/$GLOBAL_SSH_FOLDER"
fi

cp -ar ${PERSISTENT_CONFIG_FOLDER}/* ${VOLATILE_CONFIG_FOLDER}

if [ -n "$CTNR_APP_ENV" ]; then
    echo "== CONTAINER IS STARTING IN CTNR_APP_ENV=$CTNR_APP_ENV MODE =="
    mkdir -p /var/www/app/.ssh
    chmod 700 /var/www/app/.ssh
    chown user:www-data /var/www/app/.ssh
    echo "CTNR_APP_ENV=$CTNR_APP_ENV" > /var/www/app/.ssh/environment
    chmod 444 /var/www/app/.ssh/environment
    chown root: /var/www/app/.ssh/environment
    configSet /etc/ssh/sshd_config PermitUserEnvironment yes
else
    echo "== CONTAINER IS STARTING WITHOUT CTNR_APP_ENV BEING SET =="
    rm -f /var/www/app/.ssh/environment
    configSet /etc/ssh/sshd_config PermitUserEnvironment no
fi

# start container
exec /usr/bin/supervisord -c /etc/supervisord.conf
