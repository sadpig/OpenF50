#!/bin/sh
set -e
H=$1
cd /tmp && rm -rf openf50d && mkdir openf50d && cd openf50d
for f in openf50-display-load openf50-display.service openf50-desktop.service openf50-hdmi-test labwc/autostart; do
    mkdir -p "$(dirname "$f")"; wget -q -O "$f" "http://$H:8100/files/$f"
done
install -m 755 openf50-display-load /usr/local/sbin/openf50-display-load
install -m 755 openf50-hdmi-test /usr/local/bin/openf50-hdmi-test
install -m 644 openf50-display.service openf50-desktop.service /etc/systemd/system/
# install -d -o only owns the last component: create ~/.config first so it does not end up root-owned
install -d -o ubuntu -g ubuntu /home/ubuntu/.config /home/ubuntu/.config/labwc
install -m 644 -o ubuntu -g ubuntu labwc/autostart /home/ubuntu/.config/labwc/autostart
usermod -aG video,input,render ubuntu
systemctl daemon-reload
systemctl enable openf50-display.service openf50-desktop.service
sync
echo SETUP-OK
