require 'spec_helper'

# Node name (eg. slot1@linux.site) available in the system
TEST_NODE_NAME = 'slot1@condor.sitedom'

SEPARATOR = '------------------------'

describe Fitrender::Adaptor::CondorShellAdaptor do
  before :context do
    puts SEPARATOR
    @adaptor = Fitrender::Adaptor::CondorShellAdaptor.new
    puts "Loaded adaptor #{@adaptor.class.to_s}"
    puts SEPARATOR
  end

  it 'has a version number' do
    expect(Fitrender::Adaptor::Condor::VERSION).not_to be nil
  end

  it 'finds nodes' do
    nodes = @adaptor.nodes
    expect(nodes).not_to be_empty

    puts 'Found nodes:'
    nodes.each { |node| puts node.id }
    puts SEPARATOR

    expect(nodes.any? { |node| node.id.eql? TEST_NODE_NAME }).to eq(true)
  end

  it 'implements all methods' do
    unimplemented_methods = @adaptor.methods_to_implement

    unless unimplemented_methods.empty?
      puts 'Unimplemented methods:'
      unimplemented_methods.each { |method| puts method }
      puts SEPARATOR
    end
    expect(@adaptor.implements_all_methods?).to eq(true)
  end
end
