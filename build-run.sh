#!/bin/bash
# Build the disk image and run

# Kickasm path
if [ -z $KICKASM ]; then
  echo "You need to set the path to Kickasm."
  echo "Example: export KICKASM=/home/paul/work/c64/kickasm/KickAss.jar"
  exit 1
fi

# C64 debugger path
#if [ -z $C64DEBUGGERPATH ]; then
#  echo "You need to set the path to Kickasm."
#  echo "Example: export C64DEBUGGERPATH=/home/paul/work/c64/c64debugger/C64Debugger/C64Debugger"
#  exit 1
#fi

# Build asm objects
function build_kickasm {
  # File to build
  FILE=$1

  # Build the bogus unpack screen
  if [[ -f "${FILE}.prg" ]]; then
    rm ${FILE}.prg
  fi

  java -jar $KICKASM ${FILE}.asm

  if [[ ! -f "${FILE}.prg" ]]; then
    echo "Build of ${FILE} failed."
    exit 1
  fi
}

# Remove old image
if [[ -f "disk.d64" ]]; then 
  rm disk.d64
fi

# Build code
build_kickasm defeest-screen-fill/Screenfill
build_kickasm defeest-intro/Movesprite
build_kickasm badline/badline
build_kickasm hborder/hborder

# Build plasma effect
pushd ecmplasma
make all
popd

# Build new image
../spindle/spin -vv -o disk.d64 script 

# If success run the emulator
if [[ -f "disk.d64" ]]; then
  #$C64DEBUGGERPATH -autorundisk -d64 disk.d64 
  x64 ./disk.d64
fi
