#!/bin/bash

# load profile scripts
if [ -d $HOME/.profile.env.d ]; then
  for i in $HOME/.profile.env.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
