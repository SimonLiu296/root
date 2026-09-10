#!/system/bin/sh
cd /data/local/tmp
LD_PRELOAD=/data/local/tmp/preload.so /system/bin/toybox id > /data/local/tmp/exp.log 2>&1 &
