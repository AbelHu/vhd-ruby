# -*- encoding: utf-8 -*-
require File.expand_path('../lib/vhd/version', __FILE__)
require File.expand_path('../lib/vhd.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Eugene Howe"]
  gem.email         = ["eugene@xtreme-computers.net"]
  gem.description   = %q{}
  gem.summary       = %q{}
  gem.homepage      = "https://github.com/ehowe/vhd-ruby"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vhd"
  gem.require_paths = ["lib"]
  gem.version       = Vhd::VERSION

  gem.add_dependency "ffi"
end
