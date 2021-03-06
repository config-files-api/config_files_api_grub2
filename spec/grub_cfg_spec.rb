# frozen_string_literal: true

require_relative "spec_helper"
require "cfa/grub2/grub_cfg"
require "cfa/memory_file"

describe CFA::Grub2::GrubCfg do
  let(:memory_file) do
    path = File.expand_path("fixtures/grub.cfg", __dir__)
    CFA::MemoryFile.new(File.read(path))
  end
  subject(:config) do
    res = CFA::Grub2::GrubCfg.new(file_handler: memory_file)
    res.load
    res
  end

  describe "#sections" do
    it "gets menu entry in list" do
      expect(config.sections).to eq(
        [
          "openSUSE Leap 42.1",
          "openSUSE Leap 42.1, with Linux 4.1.12-1-default",
          "openSUSE Leap 42.1, with Linux 4.1.12-1-default (recovery mode)",
          "halt"
        ]
      )
    end
  end

  describe "#boot_entries" do
    it "gets boot entries list with title: and path: elements" do
      expect(config.boot_entries).to eq(
        [
          {
            title: "openSUSE Leap 42.1",
            path:  "openSUSE Leap 42.1"
          },
          {
            title: "openSUSE Leap 42.1, with Linux 4.1.12-1-default",
            path:  "Advanced options for openSUSE Leap 42.1>" \
              "openSUSE Leap 42.1, with Linux 4.1.12-1-default"
          },
          {
            title: "openSUSE Leap 42.1, with Linux 4.1.12-1-default " \
              "(recovery mode)",
            path:  "Advanced options for openSUSE Leap 42.1>" \
              "openSUSE Leap 42.1, with Linux 4.1.12-1-default (recovery mode)"
          },
          {
            title: "halt",
            path:  "halt"
          }
        ]
      )
    end

    context "grub.cfg with snapper boot entry" do
      let(:memory_file) do
        path = File.expand_path("fixtures/grub-with-snapper.cfg", __dir__)
        CFA::MemoryFile.new(File.read(path))
      end

      it "filters out unbootable entries" do
        expect(config.boot_entries).to eq(
          [
            {
              title: "SLES 12-SP2",
              path:  "SLES 12-SP2"
            },
            {
              title: "SLES 12-SP2, with Linux 4.4.13-46-default",
              path:  "Advanced options for SLES 12-SP2>" \
                     "SLES 12-SP2, with Linux 4.4.13-46-default"
            },
            {
              title: "SLES 12-SP2, with Linux 4.4.13-46-default " \
                     "(recovery mode)",
              path:  "Advanced options for SLES 12-SP2>" \
                     "SLES 12-SP2, with Linux 4.4.13-46-default (recovery mode)"
            }
          ]
        )
      end
    end

    context "grub.cfg with multiple submenus" do
      let(:memory_file) do
        path = File.expand_path("fixtures/grub_multilevel.cfg", __dir__)
        CFA::MemoryFile.new(File.read(path))
      end

      it "creates proper path in result" do
        expect(config.boot_entries).to eq(
          [{ title: "SLES 12-SP2", path: "SLES 12-SP2" },
           {
             title: "SLES 12-SP2, with Linux 4.4.30-69-default-bug1005169",
             path:  "Advanced options for SLES 12-SP2>" \
              "SLES 12-SP2, with Linux 4.4.30-69-default-bug1005169"
           },
           {
             title: "SLES 12-SP2, with Linux 4.4.21-69-default",
             path:  "Advanced options for SLES 12-SP2>"\
              "SLES 12-SP2, with Linux 4.4.21-69-default"
           },
           {
             title: "SLES 12-SP2, with Linux 4.4.21-68-default",
             path:  "Advanced options for SLES 12-SP2>"\
              "SLES 12-SP2, with Linux 4.4.21-68-default"
           },
           {
             title: "SLES 12-SP2, with Xen hypervisor",
             path:  "SLES 12-SP2, with Xen hypervisor"
           },
           {
             title: "SLES 12-SP2, with Xen 4.7.0_12-23 and "\
              "Linux 4.4.30-69-default-bug1005169",
             path:  "Advanced options for SLES 12-SP2 (with Xen hypervisor)>"\
              "Xen hypervisor, version 4.7.0_12-23>"\
              "SLES 12-SP2, with Xen 4.7.0_12-23 and " \
              "Linux 4.4.30-69-default-bug1005169"
           },
           {
             title: "SLES 12-SP2, with Xen 4.7.0_12-23 and "\
               "Linux 4.4.21-69-default",
             path:  "Advanced options for SLES 12-SP2 (with Xen hypervisor)>"\
               "Xen hypervisor, version 4.7.0_12-23>" \
               "SLES 12-SP2, with Xen 4.7.0_12-23 and Linux 4.4.21-69-default"
           },
           {
             title: "SLES 12-SP2, with Xen 4.7.0_12-23 and "\
               "Linux 4.4.21-68-default",
             path:  "Advanced options for SLES 12-SP2 (with Xen hypervisor)>"\
               "Xen hypervisor, version 4.7.0_12-23>"\
               "SLES 12-SP2, with Xen 4.7.0_12-23 and Linux 4.4.21-68-default"
           }]
        )
      end
    end
  end

  describe "#save" do
    it "raises NotImplementedError" do
      expect { config.save }.to raise_error(NotImplementedError)
    end
  end
end
