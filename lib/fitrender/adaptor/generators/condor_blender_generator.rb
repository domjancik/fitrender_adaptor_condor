module Fitrender
  module Adaptor
    module Generators
      class CondorBlenderGenerator < Fitrender::Adaptor::Generator
        include Fitrender::ConfigurationConcerns::Framable

        # TODO multiple scenes support, for now the scenes option is ignored

        def initialize
          super

          option_add 'scenes', '', 'The scenes to render, separate by commas, leave blank to use the active scene'
        end

        def generate(scene, adaptor)
          @adaptor = adaptor

          granularity = renderer.frame_granularity

          array = []
          frames.inject(array) do |arr, frame|
            (0..(calculate_tile_count(granularity) - 1)).each do |index|
              arr << generate_frame(scene, frame, granularity, index)
            end
          end

          array
        end

        def stripped_scene_name(scene)
          match = /(.+?)\.blend/.match File.basename(scene.path)
          match[1]
        end

        def sub_filename(scene, frame, tile_index)
          "#{render_filename(scene, frame, tile_index)}.sub"
        end

        def blender_output_filename(scene, tile_index)
          "#{@adaptor.render_path}/#{stripped_scene_name(scene)}_#{tile_index.to_s.rjust(2, '0')}_####"
        end

        def render_filename(scene, frame, tile_index)
          "#{stripped_scene_name(scene)}_#{tile_index.to_s.rjust(2, '0')}_#{frame.to_s.rjust(4, '0')}"
        end

        def calculate_tile_count(granularity)
          1 / granularity ** 2
        end

        def calculate_tile(granularity, tile_index)
          tiles_per_row = 1 / granularity
          row = (tile_index / tiles_per_row).floor
          col = tile_index % tiles_per_row

          min_x = col * granularity
          min_y = row * granularity
          max_x = [min_x + granularity, 1].min
          max_y = [min_y + granularity, 1].min

          [ min_x, min_y, max_x, max_y ]
        end

        # @param [Fitrender::Adaptor::Scene] scene
        # @param [Fixnum] frame
        # @param [Array] border_arr array with four elements specifying the render border [min_x, min_y, max_x, max_y]
        # @param [Fixnum] granularity
        # @param [Fixnum] tile_index
        def generate_frame(scene, frame, granularity, tile_index)
          blender_script_path = "#{File.dirname(__FILE__)}/scripts/blender_frame.sh"
          blender_border_script_path = "#{File.dirname(__FILE__)}/scripts/blender_cli_render_border.py"
          border = calculate_tile(granularity, tile_index).join ','
          submit_file_contents = "# Render a single frame with Blender
Universe		= vanilla
Executable              = #{blender_script_path}
arguments               = \"#{scene.path} #{blender_output_filename(scene, tile_index)} #{frame} #{border}\"
when_to_transfer_output = ON_EXIT
transfer_input_files    = #{blender_border_script_path}
should_transfer_files   = YES
log                     = #{@adaptor.log_path}/#{stripped_scene_name(scene)}.log
output                  = #{@adaptor.out_path}/#{stripped_scene_name(scene)}.out
queue"
          # FIXME Make all the paths settable via adaptor settings
          sub_file_path = "#{@adaptor.subs_path}/#{sub_filename(scene, frame, tile_index)}"
          sub_file = open(sub_file_path, 'w')
          sub_file.write submit_file_contents
          sub_file.close

          job_name = "Frame #{frame}"
          job_name += " tile #{tile_index + 1}/#{calculate_tile_count(granularity).to_i}" if granularity < 1

          {
              sub_file: File.absolute_path(sub_file),
              render_path: "#{@adaptor.render_path}/#{render_filename(scene, frame, tile_index)}.png",
              name: job_name
          }
        end
      end
    end
  end
end
