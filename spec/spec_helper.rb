$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

def load_data(path)
  File.read(File.expand_path("data/#{path}", __dir__))
end

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start

  # for coverage we need to load all ruby files
  src_location = File.expand_path("../", __dir__)
  Dir["#{src_location}/lib/**/*.rb"].each { |f| require_relative f }

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end
