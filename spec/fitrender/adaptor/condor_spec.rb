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

  it 'finds a single node' do
    node = @adaptor.node(TEST_NODE_NAME)
    expect(node.id).to eq(TEST_NODE_NAME)
  end

  context 'scene submission' do
    MAX_WAIT = 20

    before :context do
      scene = Fitrender::Adaptor::Scene.new
      scene.renderer = 'Blender'
      scene.filename = "#{File.dirname(File.absolute_path(__FILE__))}/test_scene.blend"

      puts SEPARATOR
      puts 'Submitting scene'
      puts SEPARATOR

      @job_ids = @adaptor.submit(scene)

      puts 'Resulted in following jobs:'
      @job_ids.each do |job_id|
        puts job_id
      end

      puts SEPARATOR
    end

    it 'has valid job ids' do
      @job_ids.each do |job_id|
        expect(job_id).to match(/^[0-9]+$/)
      end
    end

    it 'finds the scene jobs in the queue' do
      queue_states = [
          Fitrender::Adaptor::States::JOB_STATE_IDLE,
          Fitrender::Adaptor::States::JOB_STATE_RUNNING
      ]

      @job_ids.each do |job_id|
        job_state = @adaptor.job_state(job_id)
        expect(queue_states).to include(job_state)
      end
    end

    it "solves the scene in up to #{MAX_WAIT} seconds" do
      waiting_for = 0
      all_completed = false

      while waiting_for < MAX_WAIT
        sleep 2
        waiting_for += 2
        all_completed = @job_ids.all? do |job_id|
          @adaptor.job_state(job_id).eql? Fitrender::Adaptor::States::JOB_STATE_COMPLETED
        end
        if all_completed
          puts "Completed in ~#{waiting_for} seconds"
          break
        end
      end

      expect(all_completed).to eq(true)
    end

    # TODO Scene solving
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
