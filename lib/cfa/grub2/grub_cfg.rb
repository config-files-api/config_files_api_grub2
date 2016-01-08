require "cfa/base_model"

module CFA
  module Grub2
    # Represents generated grub configuration at /boot/grub2/grub.cfg
    #
    # Upstream docs:
    # http://www.gnu.org/software/grub/manual/html_node/Configuration.html
    #
    # Main features:
    #
    # - List of generated sections
    class GrubCfg < BaseModel
      PATH = "/boot/grub2/grub.cfg"

      # @private only internal parser
      class Parser
        def self.parse(string)
          menu_lines = string.lines.grep(/menuentry\s*'/)
          menu_lines.map { |line| line[/\s*menuentry\s*'([^']+)'.*/, 1] }
        end

        def self.serialize(_model)
          raise NotImplementedError,
            "Serializing not implemented, use grub-mkconfig or Bootloader::Grub2"
        end

        def self.empty
          []
        end
      end

      def initialize(file_handler: nil)
        super(Parser, PATH, file_handler: file_handler)
      end

      # @return [Array<String>] sections from grub.cfg in order as they appear
      def sections
        data
      end
    end
  end
end
