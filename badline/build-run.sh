#!/bin/bash
if [[ -f badline.prg ]]; then
  rm badline.prg
fi

# Build the object
java -jar $KICKASM badline.asm

if [[ -f badline.prg ]]; then
  x64 badline.prg
fi
