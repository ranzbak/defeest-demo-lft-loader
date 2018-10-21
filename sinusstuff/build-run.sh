#!/bin/bash
if [[ -f sinusstuff.prg ]]; then
  rm sinusstuff.prg
fi

# Build the object
java -jar $KICKASM sinusstuff.asm

if [[ -f sinusstuff.prg ]]; then
  x64 -keybuf 'sys 4096\n' sinusstuff.prg 
fi
