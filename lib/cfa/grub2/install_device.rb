require "cfa/base_model"

module CFA
  module Grub2
    # specific parser for install devices.
    # File format is easy element per line without comments.
    # for better readability special values generic_mbr and activate is at
    # the end of file
    module InstallDeviceParser
      # returns list of non-empty lines
      def self.parse(string)
        string.lines.map(&:strip).delete_if(&:empty?)
      end

      # gets list of devices and create file content from it
      def self.serialize(data)
        activate = data.delete("activate")
        generic_mbr = data.delete("generic_mbr")

        res = data.map { |disk| disk + "\n" }

        res << "activate\n" if activate
        res << "generic_mbr\n" if generic_mbr

        res
      end
    end

    # Model representing configuration in file /etc/default/grub_installdevice
    class InstallDevice < BaseModel
      PATH = "/etc/default/grub_installdevice"

      def initialize(file_handler: File)
        super(InstallDeviceParser, PATH, file_handler: file_handler)
        # TODO: add to parser method to fill empty data tree
        self.data = []
      end

      # Adds new install device. Does nothing if it is already there.
      def add_device(dev)
        data << dev unless data.include?(dev)
      end

      # Removes install device. Does nothing if already not there.
      def remove_device(dev)
        data.delete(dev)
      end

      # @return [Array<String>] non-special devices from configuration
      def devices
        res = data.dup
        res.delete("generic_mbr")
        res.delete("activate")

        res
      end

      # ask if special entry for generic_mbr is there
      def generic_mbr?
        data.include?("generic_mbr")
      end

      # sets special entry generic_mbr
      def generic_mbr=(enabled)
        if enabled
          return if generic_mbr?

          data << "generic_mbr"
        else
          data.delete("generic_mbr")
        end
      end

      # Ask if special entry for activate is there
      def activate?
        data.include?("activate")
      end

      # sets special entry activate
      def activate=(enabled)
        if enabled
          return if activate?

          data << "activate"
        else
          data.delete("activate")
        end
      end
    end
  end
end
