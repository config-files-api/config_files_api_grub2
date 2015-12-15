require_relative "spec_helper"
require "cfa/grub2/grub_cfg"
require "cfa/memory_file"

describe CFA::Grub2::GrubCfg do
  let(:memory_file) do
    path = File.expand_path("../fixtures/grub.cfg", __FILE__)
    CFA::MemoryFile.new(File.read(path))
  end
  subject(:config) do
    res = CFA::Grub2::GrubCfg.new(file_handler: memory_file)
    res.load
    res
  end

  describe "#sections" do
    it "gets menu entry in list" do
      expect(config.sections).to eq([
        "openSUSE Leap 42.1",
        "openSUSE Leap 42.1, with Linux 4.1.12-1-default",
        "openSUSE Leap 42.1, with Linux 4.1.12-1-default (recovery mode)",
        "halt"
      ])
    end
  end
end
