# frozen_string_literal: true

require_relative "spec_helper"
require "cfa/grub2/default"
require "cfa/memory_file"

describe CFA::Grub2::Default do
  let(:boolean_value_class) { CFA::BooleanValue }
  let(:memory_file) { CFA::MemoryFile.new(file_content) }
  let(:config) do
    res = CFA::Grub2::Default.new(file_handler: memory_file)
    res.load
    res
  end

  describe "#timeout" do
    context "key is specified" do
      let(:file_content) { "GRUB_TIMEOUT=10\n" }
      it "returns value of GRUB_TIMEOUT key" do
        expect(config.timeout).to eq "10"
      end
    end

    context "key is missing in file" do
      let(:file_content) { "\n" }
      it "returns nil" do
        expect(config.timeout).to eq nil
      end
    end
  end

  describe "#hiddentimeout" do
    context "key is specified" do
      let(:file_content) { "GRUB_HIDDEN_TIMEOUT=10\n" }
      it "returns value of GRUB_HIDDEN_TIMEOUT key" do
        expect(config.hidden_timeout).to eq "10"
      end
    end

    context "key is missing in file" do
      let(:file_content) { "\n" }
      it "returns nil" do
        expect(config.hidden_timeout).to eq nil
      end
    end
  end

  describe "#terminal" do
    context "GRUB_TERMINAL is empty" do
      let(:file_content) { "GRUB_TERMINAL=\"\"\n" }
      it "returns nil" do
        expect(config.terminal).to eq nil
      end
    end

    context "GRUB_TERMINAL is console" do
      let(:file_content) { "GRUB_TERMINAL=\"console\"\n" }
      it "returns [:console]" do
        expect(config.terminal).to eq [:console]
      end
    end

    context "GRUB_TERMINAL is serial" do
      let(:file_content) { "GRUB_TERMINAL=\"serial\"\n" }
      it "returns [:serial]" do
        expect(config.terminal).to eq [:serial]
      end
    end

    context "GRUB_TERMINAL is gfxterm" do
      let(:file_content) { "GRUB_TERMINAL=\"gfxterm\"\n" }
      it "returns [:gfxterm]" do
        expect(config.terminal).to eq [:gfxterm]
      end
    end

    context "GRUB_TERMINAL is \"console serial\"" do
      let(:file_content) { "GRUB_TERMINAL=\"console serial\"\n" }
      it "returns [:console, :serial]" do
        expect(config.terminal).to eq [:console, :serial]
      end
    end

    context "GRUB_TERMINAL is something else" do
      let(:file_content) { "GRUB_TERMINAL=\"unknown\"\n" }
      it "raises runtime error" do
        expect { config.terminal }.to(
          raise_error(RuntimeError, /unknown GRUB_TERMINAL/)
        )
      end
    end
  end

  describe "#terminal=" do
    let(:file_content) { "GRUB_TERMINAL=\"\"\n" }

    context "list of valid options" do
      it "accepts the values" do
        config.terminal = [:serial, :console]
        config.save

        result = "GRUB_TERMINAL=\"serial console\""
        expect(memory_file.content.strip).to eq(result)
      end
    end

    context "list with some invalid option" do
      it "raises an ArgumentError exception" do
        input = [:unknown, :values]
        expect { config.terminal = input }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#serial_console=,#serial_console" do
    let(:file_content) { "GRUB_TERMINAL=\"\"\n" }

    it "sets GRUB_SERIAL_COMMAND" do
      config.serial_console = "tty"
      config.save

      result = "GRUB_TERMINAL=\"serial\"\nGRUB_SERIAL_COMMAND=\"tty\""
      expect(memory_file.content.strip).to eq(result)
      expect(config.serial_console).to eq("tty")
    end
  end

  describe "#os_prober" do
    let(:file_content) { "GRUB_DISABLE_OS_PROBER=true\n" }

    it "returns object representing boolean state" do
      expect(config.os_prober).to be_a(boolean_value_class)
      # few simple test to verify params
      expect(config.os_prober.enabled?).to eq(false)

      # and store test
      config.os_prober.enable
      config.save
      expect(memory_file.content).to eq("GRUB_DISABLE_OS_PROBER=false\n")
    end
  end

  describe "#cryptodisk" do
    let(:file_content) { "GRUB_ENABLE_CRYPTODISK=n\n" }

    it "returns object representing boolean state" do
      expect(config.cryptodisk).to be_a(boolean_value_class)
      # few simple test to verify params
      expect(config.cryptodisk.enabled?).to eq(false)

      # and store test
      config.cryptodisk.enable
      config.save
      expect(memory_file.content).to eq("GRUB_ENABLE_CRYPTODISK=y\n")
    end
  end

  describe "#recovery_entry" do
    let(:file_content) { "GRUB_DISABLE_RECOVERY=true\n" }

    it "returns object representing boolean state" do
      expect(config.recovery_entry).to be_a(boolean_value_class)
      # few simple test to verify params
      expect(config.recovery_entry.enabled?).to eq(false)

      # and store test
      config.recovery_entry.enable
      config.save
      expect(memory_file.content).to eq("GRUB_DISABLE_RECOVERY=false\n")
    end
  end

  describe "#kernel_params" do
    let(:file_content) do
      "GRUB_CMDLINE_LINUX_DEFAULT=\"quite console=S0 console=S1 vga=0x400\" " \
        "# comment 1\n"
    end

    it "returns KernelParams object" do
      kernel_params_class = CFA::Grub2::Default::KernelParams
      expect(config.kernel_params).to be_a(kernel_params_class)

      params = config.kernel_params
      expect(params.parameter("quite")).to eq true
      expect(params.parameter("verbose")).to eq false
      expect(params.parameter("vga")).to eq "0x400"
      expect(params.parameter("console")).to eq ["S0", "S1"]

      # lets place verbose after parameter "quite"
      matcher = CFA::Matcher.new(key: "quite")
      placer = CFA::AfterPlacer.new(matcher)
      params.add_parameter("verbose", true, placer)

      # lets place silent at the end
      params.add_parameter("silent", true)

      # lets change second console parameter from S1 to S2
      matcher = CFA::Matcher.new(
        key:           "console",
        value_matcher: "S1"
      )
      placer = CFA::ReplacePlacer.new(matcher)
      params.add_parameter("console", "S2", placer)

      # lets remove VGA parameter
      matcher = CFA::Matcher.new(key: "vga")
      params.remove_parameter(matcher)

      config.save
      expected_line = "GRUB_CMDLINE_LINUX_DEFAULT=" \
        "\"quite verbose console=S0 console=S2 silent\"\n"
      expect(memory_file.content).to eq(expected_line)
    end
  end

  describe "#generic_set" do
    context "value is already specified in file" do
      let(:file_content) { "GRUB_ENABLE_CRYPTODISK=false\n" }

      it "modify line" do
        config.generic_set("GRUB_ENABLE_CRYPTODISK", "true")
        config.save

        expect(memory_file.content).to eq("GRUB_ENABLE_CRYPTODISK=true\n")
      end
    end

    context "key is commented out in file" do
      let(:file_content) { "#bla bla\n#GRUB_ENABLE_CRYPTODISK=false\n" }

      it "uncomment and modify line" do
        config.generic_set("GRUB_ENABLE_CRYPTODISK", "true")
        config.save

        # TODO: check why augeas sometimes espace and sometimes not
        expected_content = "#bla bla\nGRUB_ENABLE_CRYPTODISK=\"true\"\n"
        expect(memory_file.content).to eq(expected_content)
      end
    end

    context "key is missing in file" do
      let(:file_content) { "" }

      it "inserts line" do
        config.generic_set("GRUB_ENABLE_CRYPTODISK", "true")
        config.save

        # TODO: check why augeas sometimes espace and sometimes not
        result = "GRUB_ENABLE_CRYPTODISK=\"true\""
        expect(memory_file.content.strip).to eq(result)
      end
    end
  end
end
