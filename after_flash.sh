#before doing this, sdb to artik
echo "Before doing this, launch direct_set_debug.sh --sdb-set on Artik"
./common_plugin_tizen3.0_artik10/common_plugin_tizen3.0_artik10.sh

#ZYPPER
./zypper_script/artik-tizen/artik_tizen_zypper_install.sh

#TIMEZONE
sdb shell vconftool -g 6514 set -t string db/setting/cityname_id "IDS_WCL_BODY_CITYNAME_MOSCOW"
sdb shell vconftool -g 6514 set -t string db/setting/timezone_id "Europe/Moscow"
sdb shell rm -f /opt/etc/localtime
sdb shell ln -s /usr/share/zoneinfo/Europe/Moscow /opt/etc/localtime

#LIBS
echo "Installing libs"
sdb push ./packages/*.rpm /tmp/packages/
sdb shell rpm -Uvh /tmp/packages/libcares-devel-1.12.0-1.1.armv7l.rpm
sdb shell rpm -Uvh /tmp/packages/libopenssl-devel-1.0.2j-1.1.armv7l.rpm
sdb shell rpm -Uvh /tmp/packages/libuuid-devel-2.28-1.1.armv7l.rpm
sdb shell rpm -Uvh /tmp/packages/openssh-6.6p1-3.5.armv7l.rpm
echo -e "\n\Removing rpms from target pc\n"
sdb shell rm -rf /tmp/packages

sdb push ./packages/toybox-armv7l /usr/bin
sdb shell rm /usr/bin/toybox
sdb ln -s /usr/bin/toybox-armv7l /usr/bin/toybox

#LORA
./LORA/lora.sh
