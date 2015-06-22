module Fitrender
  module Adaptor
    module Renderers
      class Blender < Fitrender::Adaptor::Renderer
        include Fitrender::ConfigurableWithFile

        def initialize
          super
          option_add 'frame_granularity', '1', 'How much to split single frames into multiple jobs. 1 is no splitting, lower numbers increase splitting.'

          self.id = 'Blender'
          self.extension = 'blend'
          self.generator = Fitrender::Adaptor::Generators::CondorBlenderGenerator.new
        end

        def frame_granularity
          (option_value 'frame_granularity').to_f
        end
      end
    end
  end
end