require 'fitrender/adaptor/condor/version'
require 'fitrender_common'
require 'nokogiri'

require_relative 'generators/condor_blender_generator'

module Fitrender
  module Adaptor
    # Interact with HTCondor using shell commands
    class CondorShellAdaptor < Fitrender::Adaptor::BaseAdaptor
      NODE_ACTIVITY_IDLE = 'Idle'
      NODE_ACTIVITY_BUSY = 'Busy'

      # See http://pages.cs.wisc.edu/~adesmet/status.html
      JOB_STATE_UNEXPANDED = 0
      JOB_STATE_IDLE = 1
      JOB_STATE_RUNNING = 2
      JOB_STATE_REMOVED = 3
      JOB_STATE_COMPLETED = 4
      JOB_STATE_HELD = 5
      JOB_STATE_SUBMISSION_ERROR = 6

      def initialize
        super

        add_renderer(Fitrender::Adaptor::Renderer.new \
          'Blender', 'blend', Fitrender::Adaptor::Generators::CondorBlenderGenerator.new
        )
      end

      def available?
        status = `condor_status`
        $?.to_i == 0 && status.length > 0 ? true : false
      end

      # Translate Condor node Activity to FITRender node state
      def translate_node_state(condor_node_activity)
        # TODO More states
        case condor_node_activity
          when NODE_ACTIVITY_IDLE
            Fitrender::Adaptor::States::NODE_STATE_IDLE
          when NODE_ACTIVITY_BUSY
            Fitrender::Adaptor::States::NODE_STATE_BUSY
          else
            Fitrender::Adaptor::States::NODE_STATE_OTHER
        end
      end

      def parse_xml_status(status_xml)
        nodes = []

        status_xml_doc = Nokogiri::XML status_xml

        status_nodes = status_xml_doc.css 'c'
        status_nodes.each do |node_doc|
          id = node_doc.css('a[n=Name] s').text
          state = translate_node_state node_doc.css('a[n=Activity] s').text

          attribs_doc = node_doc.css('a[n!=Name]')
          attributes = {}
          attribs_doc.each do |attribute_doc|
            attrib_type = attribute_doc.attribute 'n'
            attrib_value = attribute_doc.text
            attributes[attrib_type.value.to_sym] = attrib_value
          end

          nodes << Fitrender::Adaptor::Node.new(id, state, attributes)
        end

        nodes
      end

      def nodes
        available!

        status_xml = `condor_status -xml -attributes Name,OpSys,Arch,State,Activity,LoadAvg,Mem`

        parse_xml_status status_xml
      end

      def strip_console_input(input)
        input.gsub! '"', ''
      end

      def node(node_id)
        available!

        # TODO check if stripping " is enough to prevent shell code injection
        strip_console_input node_id
        status_xml = `condor_status -xml -constraint 'Name == "#{node_id}"'`

        nodes = parse_xml_status status_xml

        raise Fitrender::NotFoundError if nodes.empty?

        return nodes[0]
      end

      # Parse the job id from a submission
      def parse_job_id(result)
        match = /cluster ([0-9]+)/.match result
        raise Fitrender::SubmissionFailedError unless match
        match[1]
      end

      def translate_job_state(condor_job_state)
        case condor_job_state
          when JOB_STATE_IDLE
            Fitrender::Adaptor::States::JOB_STATE_IDLE
          when JOB_STATE_RUNNING
            Fitrender::Adaptor::States::JOB_STATE_RUNNING
          when JOB_STATE_COMPLETED
            Fitrender::Adaptor::States::JOB_STATE_COMPLETED
          when JOB_STATE_HELD
            Fitrender::Adaptor::States::JOB_STATE_FAILED
          when JOB_STATE_SUBMISSION_ERROR
            Fitrender::Adaptor::States::JOB_STATE_FAILED
          when JOB_STATE_REMOVED
            Fitrender::Adaptor::States::JOB_STATE_FAILED
          when JOB_STATE_UNEXPANDED
            Fitrender::Adaptor::States::JOB_STATE_OTHER
        end
      end

      def submit(scene)
        renderer = detect_renderer(scene)
        subs = renderer.generate_submissions(scene)
        subs = subs.is_a?(Array) ? subs : [ subs ]

        job_ids = []

        # A list of sub files paths is expected
        subs.each do |submission|
          sub_result = `condor_submit #{submission}`
          raise Fitrender::SubmissionFailedError unless sub_result.to_i == 0
          job_ids << parse_job_id(sub_result.to_s)
        end

        job_ids
      end

      # @param [String] status_xml The XML output of either the queue or history command
      def extract_job_state(job_status_result)
        raise Fitrender::NotFoundError if job_status_result.length == 0

        statuses = job_status_result.split("\n")
        # TODO multiple proc clusters
        status_int = statuses[0].split(' ')[1].to_i
        translate_job_state status_int
      end

      def job_state(job_id)
        available!

        strip_console_input job_id

        begin
          # Active jobs
          extract_job_state `condor_q #{job_id} -format "%d " ClusterId -format "%d\n" JobStatus`
        rescue Fitrender::NotFoundError
          # Finished jobs
          extract_job_state `condor_history #{job_id} -format "%d " ClusterId -format "%d\n" JobStatus`
        end
      end
    end
  end
end
