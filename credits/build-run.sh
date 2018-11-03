#!/bin/bash
if [[ -f dj-music.prg ]]; then
  rm dj-music.prg
fi
if [[ -f look-ahead.prg ]]; then
  rm look-ahead.prg
fi
if [[ -f party-beest.prg ]]; then
  rm party-beest.prg
fi

# look-ahead.asm  party-beest.asm
# Build the object
java -jar $KICKASM dj-music.asm
java -jar $KICKASM look-ahead.asm
java -jar $KICKASM party-beest.asm

if [[ -f dj-music.prg ]]; then
  x64 dj-music.prg
fi
