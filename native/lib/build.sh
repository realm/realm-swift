lipo Products/Debug-iphoneos/libtightdb_ios.a Products/Debug-iphonesimulator/libtightdb_ios.a -create -output Debug/libtightdb_all.a
cp Products/Debug/libtightdb.a Debug/libtightdb.a
lipo Products/Release-iphoneos/libtightdb_ios.a Products/Release-iphonesimulator/libtightdb_ios.a -create -output Release/libtightdb_all.a
cp Products/Release/libtightdb.a Release/libtightdb.a
