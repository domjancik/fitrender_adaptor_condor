require 'fitrender/adaptor/condor/version'
require 'fitrender_common'
require 'nokogiri'

module Fitrender
  module Adaptor
    # Interact with HTCondor using shell commands
    class CondorShellAdaptor < Fitrender::Adaptor::BaseAdaptor
      def available?
        status = `condor_status`
        $?.to_i == 0 && status.length > 0 ? true : false
      end

      def nodes
        available!

        nodes = []

        status_xml = `condor_status -xml -attributes Name`
        status_xml_doc = Nokogiri::XML status_xml

        status_nodes = status_xml_doc.css 'c'
        status_nodes.each do |node_doc|
          id = node_doc.css('a[n=Name] s').text

          attribs_doc = node_doc.css('a[n!=Name]')
          attributes = {}
          attribs_doc.each do |attribute_doc|
            attrib_type = attribute_doc.attribute 'n'
            attrib_value = attribs_doc.text
            attributes[attrib_type.to_sym] = attrib_value
          end

          nodes << Fitrender::Node.new(id, attributes)
        end


        # status = `condor_status`
        # stat_lines = status.split(/\n/)
        # stat_lines.each do |stat_line|
        #   stat_columns = stat_line.split(/ +/)
        #   if /.+?@.+/.match stat_columns[0]
        #     nodes << Fitrender::Node.new(stat_columns[0])
        #   end
        # end

        nodes
      end

      def job_status
        available!


      end
    end
  end
end
