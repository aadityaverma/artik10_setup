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

#LORA
./LORA/lora.sh

# Systemd service files
sdb push ./dist/systemd-services/* /usr/lib/systemd/system/

# enabling and starting systemd services
for systemd_unit in ./dist/systemd-services/*; do
    stripped_filename=${systemd_unit##*/}
    extension="${stripped_filename##*.}"
    systemd_unit="${stripped_filename%.*}"
    sdb shell systemctl enable ${systemd_unit}
    sdb shell systemctl start ${systemd_unit}
done
