require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/placer"
require "cfa/matcher"

module CFA
  module Grub2
    # Represents grub device map in /etc/grub2/device_map
    # for details see https://www.gnu.org/software/grub/manual/html_node/Device-map.html
    # Main features:
    #
    # - Do not overwrite files
    # - When setting value first try to just change value if key already exists
    # - When grub key is not there, then add to file
    class DeviceMap < BaseModel
      PARSER = AugeasParser.new("device_map.lns")
      PATH = "/etc/grub2/device.map"

      def initialize(file_handler: File)
        super(PARSER, PATH, file_handler: file_handler)
        # TODO: add to parser method to fill empty data tree
        self.data = AugeasTree.new
      end

      # @return [String] grub device name for given system device
      def grub_device_for(system_dev)
        # TODO: maybe move to generic tree find key for value?
        matcher = Matcher.new(value_matcher: system_dev)
        entry = data.select(matcher)

        entry.empty? ? nil : entry.first[:key]
      end

      # @return [String] system device name for given grub device
      def system_device_for(grub_device)
        data[grub_device]
      end

      # Appends to configuration mapping between grub_device and system_device
      # @note if mapping for given grub device is already defined, it will be overwritten
      def add_mapping(grub_device, system_device)
        generic_set(grub_device, system_device)
      end

      # Removes mapping for given grub device
      def remove_mapping(grub_device)
        data.delete(grub_device)
      end

      # @return [Array<String>] list of all grub devices which have mapping. If there is no
      #   mapping, then it return empty list.
      def grub_devices
        # TODO: maybe add matcher which allow regexp for key or negative regexp
        entries = data.data.select do |entry|
          entry[:key] !~ /comment/
        end

        entries.map { |e| e[:key] }
      end
    end
  end
end
