# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "annotate-gff/version"

Gem::Specification.new do |s|
  s.name        = "annotate-gff"
  s.version     = Annotate::Gff::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Philipp Comans"]
  s.email       = ["annotate-gff@volton.otherinbox.com"]
  s.homepage    = "http://www.mol-palaeo.de/"
  s.summary     = %q{Summary goes here}
  s.description = %q{Description goes here}

  s.add_dependency "bio", "~> 1.4.1"
  s.add_dependency "nokogiri", "~> 1.4.4"
  s.add_dependency "trollop", "~> 1.16.2"
  
  s.rubyforge_project = "annotate-gff"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
