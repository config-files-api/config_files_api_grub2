# typed: strict
# frozen_string_literal: true

require "cfa/base_model"

module CFA
  module Grub2
    # specific parser for install devices.
    # File format is easy element per line without comments.
    # for better readability special values generic_mbr and activate is at
    # the end of file
    module InstallDeviceParser
      sig { params(string: String).returns(T::Array[String]) }
      # returns list of non-empty lines
      def self.parse(string)
        string.lines.map(&:strip).delete_if(&:empty?)
      end

      # gets list of devices and create file content from it
      sig { params(data: T::Array[String]).returns(String) }
      def self.serialize(data)
        # do not modify original data as serialize is not end of world
        data = data.dup

        activate = data.delete("activate")
        generic_mbr = data.delete("generic_mbr")

        res = data.join("\n")
        res << "\n" unless res.empty?

        res << "activate\n" if activate
        res << "generic_mbr\n" if generic_mbr

        res
      end

      sig { returns(T::Array[T.untyped]) }
      def self.empty
        []
      end
    end

    # Model representing configuration in file /etc/default/grub_installdevice
    class InstallDevice < BaseModel
      PATH = "/etc/default/grub_installdevice"

      sig { params(file_handler: T.untyped).void }
      def initialize(file_handler: nil)
        super(InstallDeviceParser, PATH, file_handler: file_handler)
      end

      # Adds new install device. Does nothing if it is already there.
      sig { params(dev: String).void }
      def add_device(dev)
        data << dev unless data.include?(dev)
      end

      # Removes install device. Does nothing if already not there.
      sig { params(dev: String).void }
      def remove_device(dev)
        data.delete(dev)
      end

      # @return [Array<String>] non-special devices from configuration
      sig { returns(T::Array[String]) }
      def devices
        res = data.dup
        res.delete("generic_mbr")
        res.delete("activate")

        res
      end

      # ask if special entry for generic_mbr is there
      sig { returns(T::Boolean) }
      def generic_mbr?
        data.include?("generic_mbr")
      end

      # sets special entry generic_mbr
      sig { params(enabled: T::Boolean).void }
      def generic_mbr=(enabled)
        if enabled
          return if generic_mbr?

          data << "generic_mbr"
        else
          data.delete("generic_mbr")
        end
      end

      # Ask if special entry for activate is there
      sig { returns(T::Boolean) }
      def activate?
        data.include?("activate")
      end

      # sets special entry activate
      sig { params(enabled: T::Boolean).void }
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
