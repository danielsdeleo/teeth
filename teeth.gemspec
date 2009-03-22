# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{teeth}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel DeLeo"]
  s.date = %q{2009-03-21}
  s.description = %q{Fast log file parsing in Ruby}
  s.email = %q{ddeleo@basecommander.net}
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "ext/extconf.rb", "ext/tokenize_apache_logs.yy", "ext/tokenize_apache_logs.yy.c", "lib/teeth.rb", "spec/fixtures/access.log", "spec/fixtures/big-access.log", "spec/fixtures/big-error.log", "spec/fixtures/error.log", "spec/fixtures/med-error.log", "spec/spec.opts", "spec/spec_helper.rb", "spec/unit/tokenize_apache_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/danielsdeleo/teeth}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = [["lib"]]
  s.required_ruby_version = Gem::Requirement.new("<= 1.9.0")
  s.rubyforge_project = %q{bloomfilter}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Fast log file parsing in Ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
