#!/usr/bin/bash

# DeviceInfo
VirtFPS=30
VirtHeight=986
VirtWidth=480
VirtKernelDIR=DVI-I-1
VirtScreen=DVI-I-1-1
PrimaryScreen=HDMI-A-0

# Position/Offset
VirtPosition="--left-of $PrimaryScreen"
VirtOffset="+0+0" #+1920+0

# VNC Config
VNCPort=5900
VNCOption="-rfbauth $(realpath ~/.vnc/secpasswd) -ZlibLevel 9 -RawKeyboard 1"
VNCFPS=30

# VAR
HANDLE=cvt # gtf
MODE=$($HANDLE $VirtWidth $VirtHeight $VirtFPS | grep Modeline | awk '{gsub(/[ \t]+$/,""); print $1=""; print $0 }' | tail -c +1)
NAME=$(echo "$MODE" | awk '{gsub(/[ \t]+$/,""); print $1 }' | tail -c +3 | head -c -2)
INFO=$(echo "$MODE" | awk '{gsub(/[ \t]+$/,""); print $1=""; print $0 }' | tail -c +4)
POLLING=$(echo "1000/${VNCFPS}" | bc)

# Enable sub output
sudo modprobe evdi initial_device_count=1
echo on | sudo tee /sys/kernel/debug/dri/1/$VirtKernelDIR/force > /dev/null
sleep 3
xrandr --setprovideroutputsource 1 0

# Create mode
sh -c "
xrandr --newmode $NAME  $INFO
xrandr --addmode $VirtScreen $NAME
xrandr --output $VirtScreen --scale 1x1 --mode $NAME $VirtPosition --output $PrimaryScreen --scale 0.9999x0.9999
"

# Run vnc
sleep 1
#x0vncserver
trap "
xrandr --output $VirtScreen --off --output $PrimaryScreen --scale 1x1
xrandr --delmode $VirtScreen $NAME
xrandr --rmmode $NAME
" INT
bash -c "x0vncserver --fg -localhost no -Geometry ${VirtWidth}x${VirtHeight}${VirtOffset} -FrameRate $VNCFPS -PollingCycle $POLLING -rfbport $VNCPort $VNCOption"
