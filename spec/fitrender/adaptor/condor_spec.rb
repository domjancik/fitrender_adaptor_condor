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

    def spec_dir
      File.dirname(File.absolute_path(__FILE__))
    end

    before :context do
      scene = Fitrender::Adaptor::Scene.new(
          renderer_id: 'Blender',
          path: "#{spec_dir}/test_scene.blend"
      )

      puts SEPARATOR
      puts 'Submitting scene'
      puts SEPARATOR

      @jobs = @adaptor.submit(scene)

      puts 'Resulted in following jobs:'
      @jobs.each do |job|
        puts job
      end

      puts SEPARATOR
    end

    it 'has valid job ids' do
      @jobs.each do |job|
        expect(job[:id]).to match(/^[0-9]+$/)
      end
    end

    it 'finds the scene jobs in the queue' do
      queue_states = [
          Fitrender::Adaptor::States::JOB_STATE_IDLE,
          Fitrender::Adaptor::States::JOB_STATE_RUNNING
      ]

      @jobs.each do |job|
        job_state = @adaptor.job_state(job[:id])
        expect(queue_states).to include(job_state)
      end
    end

    it "solves the scene in up to #{MAX_WAIT} seconds" do
      waiting_for = 0
      all_completed = false

      while waiting_for < MAX_WAIT
        sleep 2
        waiting_for += 2
        all_completed = @jobs.all? do |job|
          @adaptor.job_state(job[:id]).eql? Fitrender::Adaptor::States::JOB_STATE_COMPLETED
        end
        if all_completed
          puts "Completed in ~#{waiting_for} seconds"
          break
        end
      end

      expect(all_completed).to eq(true)
    end

    it 'renders correctly' do
      # One job is expected (1 simple frame)
      result_path = @jobs[0][:path]
      # Compare the finished render with a reference image, requires ImageMagick
      puts 'Comparing images with'
      cmp_command = "compare -metric mae \"#{spec_dir}/test_result.png\" \"#{result_path}\" /tmp/diff.png"
      puts cmp_command
      cmp_result = `#{cmp_command}`
      expect(cmp_result.to_i).to eq(0)
    end
  end

  context 'animated scene submission' do
    MAX_WAIT = 20

    def spec_dir
      File.dirname(File.absolute_path(__FILE__))
    end

    before :context do
      scene = Fitrender::Adaptor::Scene.new(
          renderer_id: 'Blender',
          path: "#{spec_dir}/test_scene.blend",
          options: { 'frames' => '1-3,4' }
      )

      puts SEPARATOR
      puts 'Submitting scene'
      puts SEPARATOR

      @jobs = @adaptor.submit(scene)

      puts 'Resulted in following jobs:'
      @jobs.each do |job|
        puts job
      end

      puts SEPARATOR
    end

    it 'has valid job ids' do
      @jobs.each do |job|
        expect(job[:id]).to match(/^[0-9]+$/)
      end
    end

    it 'has a job for each frame' do
      expect(@jobs.count).to eq(4)
    end

    it "solves the scene in up to #{MAX_WAIT} seconds" do
      waiting_for = 0
      all_completed = false

      while waiting_for < MAX_WAIT
        sleep 2
        waiting_for += 2
        all_completed = @jobs.all? do |job|
          @adaptor.job_state(job[:id]).eql? Fitrender::Adaptor::States::JOB_STATE_COMPLETED
        end
        if all_completed
          puts "Completed in ~#{waiting_for} seconds"
          break
        end
      end

      expect(all_completed).to eq(true)
    end

    it 'renders correctly' do
      # Compare the finished render with a reference image, requires ImageMagick
      @jobs.each do |job|
        result_path = job[:path]
        puts 'Comparing images with'
        cmp_command = "compare -metric mae \"#{spec_dir}/test_result.png\" \"#{result_path}\" /tmp/diff.png"
        puts cmp_command
        cmp_result = `#{cmp_command}`
        expect(cmp_result.to_i).to eq(0)
      end
    end
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
