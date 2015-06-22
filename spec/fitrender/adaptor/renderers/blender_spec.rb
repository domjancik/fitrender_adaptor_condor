require 'spec_helper'

# Tests for Blender renderer and its generator
describe Fitrender::Adaptor::Renderers::Blender do
  before :example do
    @renderer = Fitrender::Adaptor::Renderers::Blender.new
    @generator = @renderer.generator
    @scene = Fitrender::Adaptor::Scene.new(renderer_id: 'Blender', path: 'scene.blend', options: {})
    @adaptor = Fitrender::Adaptor::CondorShellAdaptor.new
  end

  context 'frame splitting according to granularity' do
    it 'can calculate number of required tiles' do
      expect(@generator.calculate_tile_count(1)).to eq(1)
      expect(@generator.calculate_tile_count(0.5)).to eq(4)
      expect(@generator.calculate_tile_count(0.25)).to eq(16)
    end

    it 'can calculate tile according to granularity and index' do
      expect(@generator.calculate_tile(1, 0)).to eq([0,0,1,1])

      expect(@generator.calculate_tile(0.5, 0)).to eq([ 0  , 0  , 0.5, 0.5 ])
      expect(@generator.calculate_tile(0.5, 1)).to eq([ 0.5, 0  , 1  , 0.5 ])
      expect(@generator.calculate_tile(0.5, 2)).to eq([ 0  , 0.5, 0.5, 1   ])
      expect(@generator.calculate_tile(0.5, 3)).to eq([ 0.5, 0.5, 1  , 1   ])
    end

    # it 'has a working generate method for multiple tiles' do
    #
    # end
    #
    it 'creates number of submissions according to granularity' do
      @renderer.option_set_value 'frame_granularity', '1'
      expect(@renderer.generate_submissions(@scene, @adaptor).length).to eq(1)

      @renderer.option_set_value 'frame_granularity', '0.5'
      expect(@renderer.generate_submissions(@scene, @adaptor).length).to eq(4)

      @renderer.option_set_value 'frame_granularity', '0.25'
      expect(@renderer.generate_submissions(@scene, @adaptor).length).to eq(16)
    end
  end

end