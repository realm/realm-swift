# Change version when new core is released
REALM_CORE_VERSION=0.21.0

if [ -z "${SRCROOT}" ]; then
    SRCROOT="$(pwd)"
fi

if ! [ -d core ]; then
    /usr/bin/curl -s http://static.realm.io/downloads/core/core-${REALM_CORE_VERSION}.zip -o /tmp/core-${REALM_CORE_VERSION}.zip
    cd ${SRCROOT}
    /usr/bin/unzip /tmp/core-${REALM_CORE_VERSION}.zip
    /bin/rm -f /tmp/core-${REALM_CORE_VERSION}.zip
fi
