require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/placer"
require "cfa/matcher"

module CFA
  module Grub2
    # Represents grub device map in /boot/grub2/device_map
    # for details see https://www.gnu.org/software/grub/manual/html_node/Device-map.html
    # Main features:
    #
    # - Do not overwrite files
    # - When setting value first try to just change value if key already exists
    # - When grub key is not there, then add to file
    # - checks and raise exception if number of mappings exceed limit 8.
    #   Limitation is caused by BIOS Int 13 used by grub2 for selecting boot
    #   device.
    class DeviceMap < BaseModel
      PARSER = AugeasParser.new("device_map.lns")
      PATH = "/boot/grub2/device.map".freeze

      def initialize(file_handler: nil)
        super(PARSER, PATH, file_handler: file_handler)
      end

      def save(changes_only: false)
        raise "Too many grub devices. Limit is 8." if grub_devices.size > 8

        super
      end

      # @return [String] grub device name for given system device
      def grub_device_for(system_dev)
        matcher = Matcher.new(value_matcher: system_dev)
        entry = data.select(matcher)

        entry.empty? ? nil : entry.first[:key]
      end

      # @return [String] system device name for given grub device
      def system_device_for(grub_device)
        data[grub_device]
      end

      # Appends to configuration mapping between grub_device and system_device
      # @note if mapping for given grub device is already defined, it will be
      #   overwritten
      def add_mapping(grub_device, system_device)
        generic_set(grub_device, system_device)
      end

      # Removes mapping for given grub device
      def remove_mapping(grub_device)
        data.delete(grub_device)
      end

      # @return [Array<String>] list of all grub devices which have mapping.
      #   If there is no mapping, then it return empty list.
      def grub_devices
        matcher = Matcher.new { |k, _v| k !~ /comment/ }
        entries = data.select(matcher)

        entries.map { |e| e[:key] }
      end
    end
  end
end
