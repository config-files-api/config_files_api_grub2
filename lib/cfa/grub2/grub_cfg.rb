require "cfa/base_model"

module CFA
  module Grub2
    # Represents generated grub configuration at /boot/grub2/grub.cfg
    # Main features:
    #
    # - List of generated sections including translations
    class GrubCfg < BaseModel
      PATH = "/boot/grub2/grub.cfg".freeze

      # @private only internal parser
      class Parser
        def self.parse(string)
          result = []
          submenu = ""
          string.lines.each do |line|
            case line
            when /menuentry\s*'/
              entry = line[/\s*menuentry\s+'([^']+)'.*/, 1]
              result << {
                title: entry,
                path: submenu.empty? ? entry : "#{submenu}>#{entry}"
              }
            when /^}\s*\n/
              submenu = ""
            when /submenu\s/
              submenu = line[/\s*submenu\s+'([^']+)'.*/, 1]
            end
          end

          result
        end

        def self.serialize(_string)
          raise NotImplementedError,
            "Serializing not implemented, use grub2 generator"
        end

        def self.empty
          []
        end
      end

      def initialize(file_handler: nil)
        super(Parser, PATH, file_handler: file_handler)
      end

      # @return [Array<String>] sections from grub.cfg in order as they appear
      # @deprecated use instead boot_entries
      def sections
        data.map { |p| p[:title] }
      end

      # @return [Array<Hash>] return boot entries containing `title:` as shown
      # on screen and `path:` whole path usable for grub2-set-default including
      # also submenu part of path
      def boot_entries
        data
      end
    end
  end
end
