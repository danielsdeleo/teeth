# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{teeth}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel DeLeo"]
  s.date = %q{2009-03-29}
  s.description = %q{Fast log file parsing in Ruby}
  s.email = %q{ddeleo@basecommander.net}
  s.extensions = ["ext/scan_apache_logs/extconf.rb", "ext/scan_rails_logs/extconf.rb"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["LICENSE", "README.rdoc", "Rakefile", "VERSION.yml", "doc/classes/String.html", "doc/classes/Teeth.html", "doc/classes/Teeth/DuplicateDefinitionError.html", "doc/classes/Teeth/DuplicateRuleError.html", "doc/classes/Teeth/InvalidDefaultDefinitionName.html", "doc/classes/Teeth/InvalidExtensionDirectory.html", "doc/classes/Teeth/RuleStatement.html", "doc/classes/Teeth/RuleStatementGroup.html", "doc/classes/Teeth/Scanner.html", "doc/classes/Teeth/ScannerDefinition.html", "doc/classes/Teeth/ScannerDefinitionArgumentError.html", "doc/classes/Teeth/ScannerDefinitionGroup.html", "doc/classes/Teeth/ScannerError.html", "doc/created.rid", "doc/files/README_rdoc.html", "doc/files/ext/scan_apache_logs/scan_apache_logs_yy_c.html", "doc/files/ext/scan_rails_logs/scan_rails_logs_yy_c.html", "doc/files/lib/rule_statement_rb.html", "doc/files/lib/scanner_definition_rb.html", "doc/files/lib/scanner_rb.html", "doc/files/lib/teeth_rb.html", "doc/fr_class_index.html", "doc/fr_file_index.html", "doc/fr_method_index.html", "doc/index.html", "doc/rdoc-style.css", "ext/scan_apache_logs/Makefile", "ext/scan_apache_logs/extconf.rb", "ext/scan_apache_logs/scan_apache_logs.yy", "ext/scan_apache_logs/scan_apache_logs.yy.c", "ext/scan_rails_logs/Makefile", "ext/scan_rails_logs/extconf.rb", "ext/scan_rails_logs/scan_rails_logs.yy", "ext/scan_rails_logs/scan_rails_logs.yy.c", "lib/rule_statement.rb", "lib/scanner.rb", "lib/scanner_definition.rb", "lib/teeth.rb", "scanners/scan_apache_logs.rb", "scanners/scan_rails_logs.rb", "spec/fixtures/rails_1x.log", "spec/fixtures/rails_22.log", "spec/fixtures/rails_22_cached.log", "spec/fixtures/rails_unordered.log", "spec/playground/show_apache_processing.rb", "spec/spec.opts", "spec/spec_helper.rb", "spec/unit/rule_statement_spec.rb", "spec/unit/scan_apache_spec.rb", "spec/unit/scan_rails_logs_spec.rb", "spec/unit/scaner_definition_spec.rb", "spec/unit/scanner_spec.rb", "teeth.gemspec", "templates/tokenizer.yy.erb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/danielsdeleo/teeth}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = [["lib"]]
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
