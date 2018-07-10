require "cfa/base_model"
require "cfa/augeas_parser"
require "cfa/placer"
require "cfa/matcher"

module CFA
  module Grub2
    # Represents grub configuration in /etc/default/grub
    # Main features:
    #
    # - Do not overwrite files
    # - When setting value first try to just change value if key already exists
    # - When key is not set, then try to find commented out line with key and
    #   replace it with real config
    # - When even commented out code is not there, then append configuration
    #   to the end of file
    class Default < BaseModel
      attributes(
        default:        "GRUB_DEFAULT",
        distributor:    "GRUB_DISTRIBUTOR",
        gfxmode:        "GRUB_GFXMODE",
        hidden_timeout: "GRUB_HIDDEN_TIMEOUT",
        theme:          "GRUB_THEME",
        timeout:        "GRUB_TIMEOUT"
      )

      PATH = "/etc/default/grub".freeze

      def initialize(file_handler: nil)
        super(AugeasParser.new("sysconfig.lns"), PATH,
          file_handler: file_handler)
      end

      def save(changes_only: false)
        # serialize kernel params object before save
        kernels = [@kernel_params, @xen_hypervisor_params, @xen_kernel_params,
                   @recovery_params]
        kernels.each do |params|
          # FIXME: this empty prevent writing explicit empty kernel params.
          generic_set(params.key, params.serialize) if params && !params.empty?
        end

        super
      end

      def load
        super

        kernels = [kernel_params, xen_hypervisor_params, xen_kernel_params,
                   recovery_params]
        kernels.each do |kernel|
          param_line = value_for(kernel.key)
          kernel.replace(param_line) if param_line
        end
      end

      def os_prober
        @os_prober ||= BooleanValue.new(
          "GRUB_DISABLE_OS_PROBER", self,
          # grub key is disable, so use reverse logic
          true_value: "false", false_value: "true"
        )
      end

      def kernel_params
        @kernel_params ||= KernelParams.new(
          value_for("GRUB_CMDLINE_LINUX_DEFAULT"), "GRUB_CMDLINE_LINUX_DEFAULT"
        )
      end

      def xen_hypervisor_params
        @xen_hypervisor_params ||= KernelParams.new(
          value_for("GRUB_CMDLINE_XEN_DEFAULT"),
          "GRUB_CMDLINE_XEN_DEFAULT"
        )
      end

      def xen_kernel_params
        @xen_kernel_params ||= KernelParams.new(
          value_for("GRUB_CMDLINE_LINUX_XEN_REPLACE_DEFAULT"),
          "GRUB_CMDLINE_LINUX_XEN_REPLACE_DEFAULT"
        )
      end

      def recovery_params
        @recovery_params ||= KernelParams.new(
          value_for("GRUB_CMDLINE_LINUX_RECOVERY"),
          "GRUB_CMDLINE_LINUX_RECOVERY"
        )
      end

      def recovery_entry
        @recovery ||= BooleanValue.new(
          "GRUB_DISABLE_RECOVERY", self,
          # grub key is disable, so use reverse logic
          true_value: "false", false_value: "true"
        )
      end

      def cryptodisk
        @cryptodisk ||= BooleanValue.new("GRUB_ENABLE_CRYPTODISK", self,
          true_value: "y", false_value: "n")
      end

      VALID_TERMINAL_OPTIONS = [:serial, :console, :gfxterm].freeze
      # Reads value of GRUB_TERMINAL from /etc/default/grub
      #
      # GRUB_TERMINAL option allows multiple values as space separated string
      #
      # @return [Array<Symbol>, nil] an array of symbols where each symbol
      #                              represents supported terminal definition
      def terminal
        values = value_for("GRUB_TERMINAL")

        return nil if values.nil? || values.empty?

        values.split.map do |value|
          if VALID_TERMINAL_OPTIONS.include?(value.to_sym)
            value.to_sym
          else
            raise "unknown GRUB_TERMINAL option #{value.inspect}"
          end
        end
      end

      def terminal=(value)
        if !VALID_TERMINAL_OPTIONS.include?(value)
          raise ArgumentError, "invalid value #{value.inspect}"
        end

        generic_set("GRUB_TERMINAL", value.to_s)
      end

      def serial_console=(value)
        self.terminal = :serial
        generic_set("GRUB_SERIAL_COMMAND", value)
      end

      def serial_console
        value_for("GRUB_SERIAL_COMMAND")
      end

    private

      def value_for(key)
        data[key].respond_to?(:value) ? data[key].value : data[key]
      end

      # Represents kernel append line with helpers to easier modification.
      # TODO: handle quoting, maybe have own lense to parse/serialize kernel
      #       params?
      class KernelParams
        attr_reader :key

        def initialize(line, key)
          @tree = ParamTree.new(line)
          @key = key
        end

        def serialize
          @tree.to_string
        end

        # replaces kernel params with passed line
        def replace(line)
          @tree = ParamTree.new(line)
        end

        # checks if there is any parameter
        def empty?
          serialize.empty?
        end

        # gets value for parameters.
        # @return possible values are `false` when parameter missing,
        #   `true` when parameter without value placed, string if single
        #   instance with value is there and array if multiple instance with
        #   values are there.
        #
        # @example different values
        #   line = "quite console=S0 console=S1 vga=0x400"
        #   params = KernelParams.new(line)
        #   params.parameter("quite") # => true
        #   params.parameter("verbose") # => false
        #   params.parameter("vga") # => "0x400"
        #   params.parameter("console") # => ["S0", "S1"]
        #
        def parameter(key)
          values = @tree.data
                        .select { |e| e[:key] == key }
                        .map { |e| e[:value] }

          return false if values.empty?
          return values if values.size > 1
          return true if values.first == true

          values.first
        end

        # Adds new parameter to kernel command line. Uses augeas placers.
        # To replace value use {ReplacePlacer}
        def add_parameter(key, value, placer = AppendPlacer.new)
          element = placer.new_element(@tree)

          element[:operation] = :add
          element[:key]   = key
          element[:value] = value
        end

        # Removes parameter from kernel command line.
        # @param matcher [Matcher] to find entry to remove
        def remove_parameter(matcher)
          @tree.data.select(&matcher).each { |e| e[:operation] = :remove }
        end

        # Represents parsed kernel parameters tree. Parses in initialization
        # and backserilized by `to_string`.
        # TODO: replace it via augeas parser when someone write lense
        class ParamTree
          def initialize(line)
            pairs = (line || "").split(/\s/)
                                .reject(&:empty?)
                                .map { |e| e.split("=", 2) }

            @data = pairs.map do |k, v|
              {
                key:       k,
                value:     v || true, # kernel param without value have true
                operation: :keep
              }
            end
          end

          def to_string
            snippets = data.map do |e|
              if e[:value] == true
                e[:key]
              else
                "#{e[:key]}=#{e[:value]}"
              end
            end

            snippets.join(" ")
          end

          def data
            @data.reject { |e| e[:operation] == :remove }.freeze
          end

          def all_data
            @data
          end
        end
      end
    end
  end
end
