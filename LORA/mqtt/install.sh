#!/bin/bash

DIR_LORA="/etc/lora-mqtt"
DIR_MOSQ="/etc/mosquitto"

mkdir -p $DIR_LORA
mkdir -p $DIR_MOSQ

cp mosquitto /bin/
cp mqtt /bin

chmod +x /bin/mqtt
chmod +x /bin/mosquitto

cp mqtt.conf $DIR_LORA
cp mosquitto.conf $DIR_MOSQ
cp pskfile.example $DIR_MOSQ
cp pwfile.example $DIR_MOSQ
cp aclfile.example $DIR_MOSQ

chmod 644 $DIR_LORA/*
