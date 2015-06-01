require 'spec_helper'
require 'fitrender/adaptor/condor'

describe FitrenderAdaptorCondor do
  before :context do
    @adaptor = Fitrender::Adaptor::CondorShellAdaptor.new
  end

  it 'has a version number' do
    expect(Fitrender::Adaptor::Condor::VERSION).not_to be nil
  end

  it 'finds' do
    expect(false).to eq(true)
  end
end
