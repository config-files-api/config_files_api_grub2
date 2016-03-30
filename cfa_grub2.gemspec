Gem::Specification.new do |s|
  s.name        = "cfa_grub2"
  s.version     = "0.4.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Josef Reidinger"]
  s.email       = ["jreidinger@suse.cz"]
  s.homepage    = "http://github.com/config-files-api/config_files_api_grub2"
  s.license     = "LGPL-3.0"
  s.summary     = "Models for GRUB2 configuration files."
  s.description = "Models allowing easy read and modification of GRUB2" \
    " configuration files. It is a plugin for cfa framework."

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "cfa", "~> 0.3.0"

  s.files        = Dir["{lib}/**/*.rb"]
  s.require_path = "lib"
end
