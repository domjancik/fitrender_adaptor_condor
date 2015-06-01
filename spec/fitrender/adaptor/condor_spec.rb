require 'spec_helper'

# Node name (eg. slot1@linux.site) available in the system
TEST_NODE_NAME = 'slot1@condor.sited'

describe Fitrender::Adaptor::CondorShellAdaptor do
  before :context do
    @adaptor = Fitrender::Adaptor::CondorShellAdaptor.new
  end

  it 'has a version number' do
    expect(Fitrender::Adaptor::Condor::VERSION).not_to be nil
  end

  it 'finds nodes' do
    nodes = @adaptor.nodes
    expect(nodes).not_to be_empty
    expect(nodes.any? { |node| node.id.eql? TEST_NODE_NAME }).to eq(true)
  end

  it 'implements all methods' do
    unimplemented_methods = @adaptor.methods_to_implement

    puts 'Unimplemented methods:' unless unimplemented_methods.empty?
    unimplemented_methods.each { |method| puts method }
    expect(@adaptor.implements_all_methods?).to eq(true)
  end
end
