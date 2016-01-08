$LOAD_PATH << File.expand_path("../../lib", __FILE__)

require "cfa/grub2/default"
require "cfa/memory_file"
require "pp"

grub_path = File.expand_path("../data/grub.cfg", __FILE__)
memory_file = CFA::MemoryFile.new(File.read(grub_path))
config = CFA::Grub2::Default.new(file_handler: memory_file)
config.load

puts "config:"
pp config
puts ""
puts "os prober:  #{config.os_prober.enabled?}"

config.os_prober.disable
config.enable_recovery_entry "\"kernel_do_your_job=HARD!\""

config.save

puts
puts "Testing output:"
puts memory_file.content
