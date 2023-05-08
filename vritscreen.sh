#!/usr/bin/bash

##############################
#           CONFIG           #
##############################

# DeviceInfo
PrimaryScreen=HDMI-A-0
PrimaryPosition=""
VirtFPS=60
VirtHeight=1200 #1480
VirtWidth=2000 #720
VirtScale=0.58
VirtRenderScale=1
VirtPosition="--left-of %Primary%"

# VNC Config
VncPort=5900
VncOption="-rfbauth $(realpath ~/.vnc/secpasswd) -ZlibLevel 9 -RawKeyboard"
VncFPS=60

# ADB Config
AdbAutoInit=true

# DIR (EVDI config)
DIRNUM=1
VirtKernelDIR=DVI-I-1
VirtScreen=DVI-I-1-1

##############################

# VAR
HANDLE=cvt # gtf
HEIGHT=$(awk "BEGIN {print int(${VirtHeight}*${VirtScale})}")
WIDTH=$(awk "BEGIN {print int(${VirtWidth}*${VirtScale})}")
MODE=$($HANDLE $WIDTH $HEIGHT $VirtFPS | grep Modeline | awk '{gsub(/[ \t]+$/,""); print $1=""; print $0 }' | tail -c +1)
NAME=$(echo "$MODE" | awk '{gsub(/[ \t]+$/,""); print $1 }' | tail -c +3 | head -c -2)
INFO=$(echo "$MODE" | awk '{gsub(/[ \t]+$/,""); print $1=""; print $0 }' | tail -c +4)
POLLING=$(awk "BEGIN {print int(1000/${VncFPS})}")

# Create display mode
function InitOutputMode() {
  xrandr --newmode $NAME $INFO
  xrandr --addmode $VirtScreen $NAME
  xrandr --output $PrimaryScreen --scale 0.9999x0.9999 $(echo $PrimaryPosition | sed "s/%Virt%/$VirtScreen/g")\
	  --output $VirtScreen $( [ "$VirtRenderScale" != "1" ] && echo "--scale ${VirtRenderScale}x${VirtRenderScale}" ) --mode $NAME $(echo $VirtPosition | sed "s/%Primary%/$PrimaryScreen/g")
}

# Destroy display mode
function DeinitOutputMode() {
  xrandr --output $VirtScreen --off\
         --output $PrimaryScreen --scale 1x1
  xrandr --delmode $VirtScreen $NAME
  xrandr --rmmode $NAME
}

# Enable sub output (EVDI)
function InitEVDI() {
  sudo modprobe evdi initial_device_count=1
  echo on | sudo tee /sys/kernel/debug/dri/$DIRNUM/$VirtKernelDIR/force > /dev/null
  sleep 1.5
  xrandr --setprovideroutputsource $(xrandr --listproviders | grep "modesetting" | awk '{gsub(/:/,""); print $2}') $(xrandr --listproviders | grep "Source Output" | awk '{gsub(/:/,""); print $2}')
}

# Run vnc
function RunVNC() {
  bash -c "x0vncserver -Geometry $(xrandr --query | grep $VirtScreen | awk "{ if ( \$3 ~ /^\\(/ ) { print \"${WIDTH}x${HEIGHT}+0+0\" } else { print \$3 } }") -FrameRate $VncFPS -PollingCycle $POLLING -rfbport $VncPort $VncOption"
  return $?
}

# adb
function IsAdbRunning() {
  ps -e | grep adb > /dev/null
  Running=$?
  if [ "$Running" != "0" ] && [ "$AdbAutoInit" = "true" ]; then
    adb start-server
    return 0
  fi

  return $Running
}
function RunAdb() {
  IsAdbRunning
  [ "$?" == "0" ] && adb reverse tcp:$VncPort tcp:$VncPort
}

InitEVDI
InitOutputMode
RunAdb
sleep 1; trap "DeinitOutputMode" INT; RunVNC; [ "$?" != "0" ] && DeinitOutputMode

