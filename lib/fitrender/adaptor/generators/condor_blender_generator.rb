module Fitrender
  module Adaptor
    module Generators
      class CondorBlenderGenerator < Fitrender::Adaptor::Generator
        def generate(scene, settings = {})
          blender_script_path = "#{File.dirname(__FILE__)}/scripts/bledner.sh"
          submit_file_contents = "# Unix submit description file
# sleep.sub -- simple sleep job

executable              = #{blender_script_path}
log                     = sleep.log
output                  = outfile.txt
error                   = errors.txt
should_transfer_files   = Yes
when_to_transfer_output = ON_EXIT
queue"
          # FIXME /tmp is platform specific, should be settable
          sub_file = open("/tmp/blender.sub")
          sub_file.write submit_file_contents
          sub_file.close

          sub_file.absolute_path
        end
      end
    end
  end
end
