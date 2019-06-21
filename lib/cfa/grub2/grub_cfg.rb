# typed: strict
# frozen_string_literal: true

require "cfa/base_model"

module CFA
  module Grub2
    # Represents generated grub configuration at /boot/grub2/grub.cfg
    # Main features:
    #
    # - List of generated sections including translations
    class GrubCfg < BaseModel
      PATH = "/boot/grub2/grub.cfg"

      # @private only internal parser
      class Parser
        sig { params(string: String).returns(T::Array[String]) }
        def self.parse(string)
          submenu = T.let([], T::Array[String])
          string.lines.each_with_object([]) do |line, result|
            case line
            when /menuentry\s+'/ then result << parse_entry(line, submenu)
            when /^\s*}\s*\n/ then submenu.pop
            when /submenu\s+'/
              submenu.push(line[/\s*submenu\s+'([^']+)'.*/, 1])
            end
          end
        end

        sig { params(_string: String).void }
        def self.serialize(_string)
          raise NotImplementedError,
                "Serializing not implemented, use grub2 generator"
        end

        sig { returns(T::Array[T.untyped]) }
        def self.empty
          []
        end

        sig do
          params(
            line:    String,
            submenu: T::Array[String]
          ).returns(T::Hash[Symbol, String])
        end
        def self.parse_entry(line, submenu)
          entry = line[/\s*menuentry\s+'([^']+)'.*/, 1]
          submenu.push(entry)
          {
            title: entry,
            path:  submenu.join(">")
          }
        end
        private_class_method :parse_entry
      end

      sig { params(file_handler: T.untyped).void }
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
      # @note Some entries are not in fact bootable, such as the
      # "run snaper rollback" hint-only entry on SUSE. They are ignored.
      # As a hack, they are recognized by double quote delimiters while the
      # regular entries use single quotes.
      sig { returns(T::Array[T::Hash[Symbol, String]]) }
      def boot_entries
        data
      end
    end
  end
end
