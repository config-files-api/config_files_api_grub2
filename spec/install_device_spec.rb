# frozen_string_literal: true

require_relative "spec_helper"
require "cfa/grub2/install_device"
require "cfa/memory_file"

describe CFA::Grub2::InstallDevice do
  let(:memory_file) do
    CFA::MemoryFile.new(
      "/dev/disk/by-id/ata-TOSHIBA_MG03ACA100_15U5K43SF\n" \
      "/dev/sdb\n" \
      "activate\n" \
      "generic_mbr\n"
    )
  end
  let(:config) do
    res = CFA::Grub2::InstallDevice.new(file_handler: memory_file)
    res.load
    res
  end

  describe "#add_device" do
    it "adds device to as additional install device" do
      config.add_device("/dev/sda")
      expect(config.devices).to include("/dev/sda")
    end

    it "does nothing if device is already there" do
      config.add_device("/dev/sdb")
      expect(config.devices).to eq config.devices.uniq
    end
  end

  describe "#remove_device" do
    it "removes device as install device" do
      config.remove_device("/dev/sdb")
      expect(config.devices).to_not include("/dev/sdb")
    end

    it "does nothing if device is not there" do
      old_devices = config.devices
      config.remove_device("/dev/sda")
      expect(config.devices).to eq old_devices
    end
  end

  describe "#devices" do
    it "returns list of devices from configuration" do
      expect(config.devices.sort).to eq(
        [
          "/dev/disk/by-id/ata-TOSHIBA_MG03ACA100_15U5K43SF",
          "/dev/sdb"
        ]
      )
    end
  end

  describe "#generic_mbr?" do
    it "returns true if file contain generic line" do
      expect(config.generic_mbr?).to eq true
    end
  end

  describe "#generic_mbr?" do
    it "returns true if file contain generic_mbr line" do
      expect(config.generic_mbr?).to eq true
    end
  end

  describe "#generic_mbr=" do
    it "adds generic_mbr line if set to true" do
      config = CFA::Grub2::InstallDevice.new(file_handler: memory_file)
      config.generic_mbr = true
      config.save

      expect(memory_file.content).to eq "generic_mbr\n"
    end

    it "removes generic_mbr line if set to false" do
      config.generic_mbr = false
      expect(config.generic_mbr?).to eq false
    end
  end

  describe "#activate?" do
    it "returns true if file contain activate line" do
      expect(config.activate?).to eq true
    end
  end

  describe "#activate=" do
    it "adds activate line if set to true" do
      config = CFA::Grub2::InstallDevice.new(file_handler: memory_file)
      config.activate = true
      config.save

      expect(memory_file.content).to eq "activate\n"
    end

    it "removes activate line if set to false" do
      config.activate = false
      expect(config.activate?).to eq false
    end
  end
end
