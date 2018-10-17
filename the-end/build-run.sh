#!/bin/bash
if [[ -f the-end.prg ]]; then
  rm the-end.prg
fi

# Build the object
java -jar $KICKASM the-end.asm

if [[ -f the-end.prg ]]; then
  x64 -keybuf 'sys 4096\n' the-end.prg
fi
