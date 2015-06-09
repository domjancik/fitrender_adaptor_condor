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

        def generate(scene)
          frames.inject([]) do |arr, frame|
            arr << generate_frame(scene, frame)
          end
        end

        def stripped_scene_name(scene)
          match = /(.+?)\.blend/.match File.basename(scene.path)
          match[1]
        end

        def sub_filename(scene, frame)
          "#{render_filename(scene, frame)}.sub"
        end

        def blender_output_filename(scene)
          # TODO take this from an Adaptor option
          "/mnt/fitrender/renders/#{stripped_scene_name(scene)}_####"
        end

        def render_filename(scene, frame)
          "#{stripped_scene_name(scene)}_#{frame.to_s.rjust(4, '0')}"
        end

        def generate_frame(scene, frame)
          blender_script_path = "#{File.dirname(__FILE__)}/scripts/blender_frame.sh"
          submit_file_contents = "# Render a single frame with Blender
Universe		= vanilla
Executable              = #{blender_script_path}
arguments               = \"#{scene.path} #{blender_output_filename(scene)} #{frame}\"
when_to_transfer_output = ON_EXIT
log                     = /mnt/fitrender/logs/#{stripped_scene_name(scene)}.log
output                  = /mnt/fitrender/out/#{stripped_scene_name(scene)}.out
queue"
          # FIXME Make all the paths settable via adaptor settings
          sub_file = open("/mnt/fitrender/subs/#{sub_filename(scene, frame)}", 'w')
          sub_file.write submit_file_contents
          sub_file.close

          {
              sub_file: File.absolute_path(sub_file),
              render_path: "#{render_filename(scene, frame)}.png" # TODO PNG is not the only possibility, although with the current script it is
          }
        end
      end
    end
  end
end
