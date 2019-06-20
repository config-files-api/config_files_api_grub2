# typed: ignore
# frozen_string_literal: true

$LOAD_PATH << File.expand_path("../lib", __dir__)

require "cfa/grub2/default"
require "cfa/memory_file"

grub_path = File.expand_path("data/grub.cfg", __dir__)
memory_file = CFA::MemoryFile.new(File.read(grub_path))
config = CFA::Grub2::Default.new(file_handler: memory_file)
config.load

puts "config: " + config.inspect
puts ""
puts "os prober:  #{config.os_prober.enabled?}"

config.os_prober.disable
config.enable_recovery_entry "\"kernel_do_your_job=HARD!\""

config.save

puts
puts "Testing output:"
puts memory_file.content
