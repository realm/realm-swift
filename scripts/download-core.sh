if ! [ -d core ]; then
    /usr/bin/curl -s http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip -o /tmp/core-${REALM_CORE_VERSION}.zip
    /bin/rm -rf ${SRCROOT}/core
    cd ${SRCROOT}
    /usr/bin/unzip /tmp/core-${REALM_CORE_VERSION}.zip
    /bin/rm -f /tmp/core-${REALM_CORE_VERSION}.zip
fi
