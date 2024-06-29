#!/bin/sh -e

/usr/bin/godot -s addons/gut/gut_cmdln.gd -d --path "$PWD" \
    -gexit \
    --verbose
