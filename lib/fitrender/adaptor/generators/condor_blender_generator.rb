module Fitrender
  module Adaptor
    module Generators
      class CondorBlenderGenerator < Fitrender::Adaptor::Generator
        include Fitrender::ConfigurationConcerns::Framable

        def generate(scene)
          blender_script_path = "#{File.dirname(__FILE__)}/scripts/blender.sh"
          submit_file_contents = "# Unix submit description file
# sleep.sub -- simple sleep job

executable              = #{blender_script_path}
log                     = /tmp/sleep.log
output                  = /tmp/outfile.txt
error                   = /tmp/errors.txt
should_transfer_files   = Yes
when_to_transfer_output = ON_EXIT
queue"
          # FIXME /tmp is platform specific, should be settable
          sub_file = open('/tmp/blender.sub', 'w')
          sub_file.write submit_file_contents
          sub_file.close

          File.absolute_path(sub_file)
        end
      end
    end
  end
end
