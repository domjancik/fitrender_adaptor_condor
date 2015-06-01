require 'fitrender/adaptor/condor/version'
require 'fitrender/adaptor'

module Fitrender
  module Adaptor
    # Interact with HTCondor using shell commands
    class CondorShellAdaptor < BaseAdaptor
      def available?
        `condor_status`
        return true if $? == 0
        false
      end
    end
  end
end