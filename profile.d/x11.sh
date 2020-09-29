#!/bin/bash - 
if [[ `uname` = 'Linux' ]]; then
  echo -n "[X11]"
  export DISPLAY=:1
fi

