# Render border setting for Blender CLI rendering
# (c) 2015 Dominik Jancik, jancidom@fit.cvut.cz
#
# Usage:
# Try to keep the order, border values should be between 0 and 1.
# Do not use spaces after commas.
#
# blender -b SCENEFILE -p blender_cli_render_border.py -o //OUTPUT -f FRAMES -border MIN_X,MIN_Y,MAX_X,MAX_Y
# eg. blender -b scene.blend -p blender_cli_render_border.py -o //image.png -f 1 -border 0,0,0.2,0.2

import bpy
import sys

# Border arguments
arg_index = sys.argv.index('-border')
border_args_string = sys.argv[arg_index + 1]
border_args_arr = border_args_string.split(',')
# Convert values to floats
border_args_arr = map(float, border_args_arr)

def set_border(min_x, min_y, max_x, max_y):
    render = bpy.context.scene.render	
    render.use_border = 1
    render.border_min_x = min_x
    render.border_min_y = min_y
    render.border_max_x = max_x
    render.border_max_y = max_y
    
# Unpack to the set_border method
set_border(*border_args_arr)