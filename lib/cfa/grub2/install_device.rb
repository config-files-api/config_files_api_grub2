require "cfa/base_model"

module CFA
  module Grub2
    # specific parser for install devices.
    # File format is easy element per line without comments.
    # for better readability special values generic_mbr and activate is at
    # the end of file
    #
    # Upstream docs: (FIXME: incomplete)
    # https://github.com/openSUSE/perl-bootloader/blob/master/boot.readme
    module InstallDeviceParser
      # @param [String] file contents
      # @return [Array<String>] non-empty lines
      def self.parse(string)
        string.lines.map(&:strip).delete_if(&:empty?)
      end

      # Gets a list of devices and creates file contents from it.
      # @param data [Array<String>]
      # @return [String] file contents
      def self.serialize(data)
        res = data.join("\n")
        res << "\n" unless res.empty?
        res
      end

      def self.empty
        []
      end
    end

    # Model representing configuration in file /etc/default/grub_installdevice
    class InstallDevice < BaseModel
      PATH = "/etc/default/grub_installdevice"

      # @return [Array<String>] (not including the special ones)
      attr_accessor :devices

      # @return [Boolean]
      attr_accessor :generic_mbr
      alias_method :generic_mbr?, :generic_mbr

      # @return [Boolean]
      attr_accessor :activate
      alias_method :activate?, :activate

      # (This shows why a single value as the parser interface is problematic)
      def from_data
        @devices = data.dup
        @generic_mbr = @devices.delete("generic_mbr") != nil
        @activate = @devices.delete("activate") != nil
      end

      def initialize(file_handler: nil)
        super(InstallDeviceParser, PATH, file_handler: file_handler)
        from_data
      end

      def load
        super
        from_data
      end

      def save(changes_only: false)
        self.data = devices
        self.data << "generic_mbr" if generic_mbr?
        self.data << "activate"    if activate?
        # FIXME: allowing changes_only in BaseModel is wrong
        super(changes_only: false)
      end

      # Adds new install device. Does nothing if it is already there.
      def add_device(dev)
        devices << dev unless devices.include?(dev)
      end

      # Removes install device. Does nothing if already not there.
      def remove_device(dev)
        devices.delete(dev)
      end
    end
  end
end
