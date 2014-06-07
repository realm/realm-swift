#!/bin/sh
# Download and unpack core library
REALM_CORE_VERSION=0.21.0

if ! [ -d core ]; then
	/usr/bin/curl -s http://static.realm.io/downloads/core/realm-core-${REALM_CORE_VERSION}.zip -o /tmp/core-${REALM_CORE_VERSION}.zip || exit 1 
	/bin/rm -rf ${SRCROOT}/core  || exit 1 
	cd ${SRCROOT}
	/usr/bin/unzip /tmp/core-${REALM_CORE_VERSION}.zip || exit 1 
	 /bin/rm -f /tmp/core-${REALM_CORE_VERSION}.zip || exit 1 
   	mv realm-core core || exit 1 
fi

