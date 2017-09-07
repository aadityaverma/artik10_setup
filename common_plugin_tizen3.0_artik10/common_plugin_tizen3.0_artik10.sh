sdb root on

#create repository for patch files

echo -e "\n\n---- Install GL DDK ----"
sdb shell mkdir -p /tmp/pkg/
sdb push gl-ddk/pkg/*.rpm /tmp/pkg/
sdb shell rpm -e --nodeps coregl
sdb shell rpm -e --nodeps libwayland-drm
sdb shell rpm -e --nodeps libwayland-egl
sdb shell rpm -e --nodeps libtpl-egl
sdb shell rpm -e --nodeps opengl-es-mali-midgard
sdb shell rpm -e --nodeps opengl-es-virtual-drv
sdb shell rpm -e --nodeps mesa-libglapi
sdb shell rpm -e --nodeps mesa
sdb shell rpm -e --nodeps mesa-libEGL
sdb shell rpm -e --nodeps mesa-libGLESv2
sdb shell rpm -Uvh --nodeps --force /tmp/pkg/*.rpm
sdb shell rm -rf /tmp/pkg
sdb push gl-ddk/conf/99-GPU-Acceleration.rules /etc/udev/rules.d/

echo -e "\n\n---- Install Zigbee Plugin ----"
sdb shell mkdir -p /tmp/pkg/
sdb push zigbee/pkg/*.rpm /tmp/pkg/
sdb shell rpm -Uvh --nodeps --force /tmp/pkg/*.rpm
sdb shell rm -rf /tmp/pkg

######################################################################
echo -e "\n\n---- Temporary patch ----"
sdb shell mkdir -p /tmp/patchtmp

sdb push target/*.cfg /tmp/patchtmp

sdb shell cp -f /tmp/patchtmp/e_comp_artik.cfg /usr/share/enlightenment/data/config/tizen-common/e_comp.cfg
sdb shell rm -rf /var/lib/enlightenment/.e

sdb shell rm -rf /tmp/patchtmp
######################################################################

echo -e "\n\n----- Sync & Reboot -----\n"
sdb shell sync
sdb shell reboot -f
