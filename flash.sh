
#before doing this, type fastboot in Artik's boot console (stop autoboot)
cd ./tizen-common-artik_20170111.3_common-boot-armv7l-artik10
sudo fastboot flash env params.bin
sudo fastboot flash bootloader u-boot.bin
sudo fastboot flash kernel zImage
sudo fastboot flash dtb exynos5422-artik10.dtb
sudo fastboot flash modules modules.img
cd ..
cd ./tizen-common-artik_20170111.3_common-wayland-3parts-armv7l-artik-wlan
sudo fastboot flash -S 0 rootfs rootfs.img
sudo fastboot flash system-data system-data.img
sudo fastboot flash user user.img
cd ..
