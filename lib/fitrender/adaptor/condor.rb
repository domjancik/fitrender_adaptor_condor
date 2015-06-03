require 'fitrender/adaptor/condor/version'
require 'fitrender_common'
require 'nokogiri'

require_relative 'generators/condor_blender_generator'

module Fitrender
  module Adaptor
    # Interact with HTCondor using shell commands
    class CondorShellAdaptor < Fitrender::Adaptor::BaseAdaptor
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
      def translate_state(condor_state)
        # TODO More states
        case condor_state
          when 'Idle'
            Fitrender::Adaptor::States::NODE_STATE_IDLE
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
          state = translate_state node_doc.css('a[n=Activity] s').text

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

      def node(node_id)
        available!

        # TODO check if stripping " is enough to prevent shell code injection
        node_id.gsub! '"', ''
        status_xml = `condor_status -xml -constraint 'Name == "#{node_id}"'`

        nodes = parse_xml_status status_xml

        raise Fitrender::NotFoundError if nodes.empty?

        return nodes[0]
      end

      def job_status
        available!

        # TODO
      end
    end
  end
end
