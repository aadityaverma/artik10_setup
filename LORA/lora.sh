sdb shell mkdir /etc/lora-mqtt
sdb shell mkdir /etc/mosquitto
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/dist/mqtt /usr/bin
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/mosquitto/mosquitto.conf /etc/mosquitto
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/lora-mqtt/dist/openwrt/files/mqtt.conf /etc/lora-mqtt
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/lora-mqtt/dist/openwrt/files/mqtt.lora.init /etc/lora-mqtt
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/mosquitto/lib/libmosquitto.so /usr/lib
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/mosquitto/src/mosquitto /bin
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/mosquitto/client/mosquitto_sub /usr/bin/
sdb push /home/volkova_ta/artik_boot/artik10/LORA/LORA/mosquitto/client/mosquitto_pub /usr/bin/
sdb shell useradd mosquitto
