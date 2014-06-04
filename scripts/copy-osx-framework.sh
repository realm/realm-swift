rm -rf ${SRCROOT}/build/${CONFIGURATION}/OSX/${PRODUCT_NAME}.framework
mkdir -p ${SRCROOT}/build/${CONFIGURATION}/OSX/${PRODUCT_NAME}.framework
( cd ${BUILD_DIR}/${CONFIGURATION}/${PRODUCT_NAME}.framework && tar cf - . ) | ( cd ${SRCROOT}/build/${CONFIGURATION}/OSX/${PRODUCT_NAME}.framework && tar xf - )
