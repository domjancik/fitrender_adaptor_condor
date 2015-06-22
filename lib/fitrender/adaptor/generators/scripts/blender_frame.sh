#!/bin/sh
blender -b "$1" -P "blender_cli_render_border.py" -o "$2" -F PNG -x 1 -f "$3" -border "$4"