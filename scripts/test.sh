#!/bin/sh -e

/usr/bin/godot \
    -s addons/gut/gut_cmdln.gd \
    --path "$PWD" \
    -gexit \
    --verbose
