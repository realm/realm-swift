#!/bin/sh

swift build -Xcxx -IRealm/ObjectStore/src -Xcxx -Isync-3.5.6/include -Xcxx -DREALM_ENABLE_SYNC=1
