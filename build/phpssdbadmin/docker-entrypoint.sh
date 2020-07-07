#!/usr/bin/env bash

PATCH_LOCK=/tmp/patched.lock

if [[ -f ${PATCH_LOCK} ]]; then
	echo "Patch already applied, skipping"
else
    if [[ -z "${PSA_NO_CAPTCHA}" ]]; then
        # Repairs broken captcha
        SAFEUTIL_SCRIPT=/var/www/html/app/classes/SafeUtil.php
        sed -e "s/, '.'.Html::host()//g" \
            -i ${SAFEUTIL_SCRIPT}
    else
        # Turns captcha validation off
        LOGIN_SCRIPT=/var/www/html/app/controllers/login.php
        sed -e '/if(!SafeUtil::verify_captcha/,+3 s/^/#/' \
            -i ${LOGIN_SCRIPT}

        # Removes captcha from login page
        LOGIN_TPL=/var/www/html/app/views/login.tpl.php
        sed -e '/<img id="captcha"/,+1d' \
            -i ${LOGIN_TPL}
    fi
    touch ${PATCH_LOCK}
fi

if [[ -z "${PSA_EXTERNAL_CONFIG}" ]]; then
    SSDB_HOST=${SSDB_HOST:-ssdb}
    SSDB_PORT=${SSDB_PORT:-8888}
    SSDB_PASSWORD=${SSDB_PASSWORD:-}
    USERNAME=${USERNAME:-admin}
    PASSWORD=${PASSWORD:-password}

    CONF_FILE=/var/www/html/app/config/config.php
    cat <<EOM >${CONF_FILE}
<?php
define('ENV', 'online');
return array(
    'env' => ENV,
    'logger' => array(
        'level' => 'all', // none/off|(LEVEL)
        'dump' => 'file', // none|html|file, 可用'|'组合
        'files' => array( // ALL|(LEVEL)
            #'ALL'	=> dirname(__FILE__) . '/../../logs/' . date('Y-m') . '.log',
        ),
    ),
    'servers' => array(
        array(
            'host' => '${SSDB_HOST}',
            'port' => '${SSDB_PORT}',
            'password' => '${SSDB_PASSWORD}',
        ),
    ),
    'login' => array(
        'name' => '${USERNAME}',
        'password' => '${PASSWORD}', // at least 6 characters
    ),
);
EOM

    echo "phpssdbadmin configuration:"
    echo " - SSDB_HOST     : ${SSDB_HOST}"
    echo " - SSDB_PORT     : ${SSDB_PORT}"
    echo " - SSDB_PASSWORD : ${SSDB_PASSWORD}"
    echo " - USERNAME      : ${USERNAME}"
    echo " - PASSWORD      : ${PASSWORD}"
else
    echo "phpssdbadmin configuration:"
    echo " - PSA_EXTERNAL_CONFIG : True"
fi

exec "$@"