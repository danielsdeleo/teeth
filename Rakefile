require "spec/rake/spectask"
require "rake/clean"
require "rake/rdoctask"

desc "Run all of the specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"spec/spec.opts\""]
  t.fail_on_error = false
end

task :default => :spec

namespace :spec do

  desc "Generate HTML report for failing examples"
  Spec::Rake::SpecTask.new('report') do |t|
    t.spec_files = FileList['failing_examples/**/*.rb']
    t.spec_opts = ["--format", "html:doc/tools/reports/failing_examples.html", "--diff", '--options', '"spec/spec.opts"']
    t.fail_on_error = false
  end
  
end

Rake::RDocTask.new do |rdt|
  rdt.rdoc_dir = "doc"
  rdt.main = "README.rdoc"
  rdt.rdoc_files.include("README.rdoc", "lib/*", "ext/*/*.yy.c")
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'teeth'
    s.summary = 'Fast log file parsing in Ruby'
    s.description = s.summary
    s.email = 'ddeleo@basecommander.net'
    s.homepage = "http://github.com/danielsdeleo/teeth"
    s.platform = Gem::Platform::RUBY 
    s.has_rdoc = true
    s.extra_rdoc_files = ["README.rdoc"]
    s.require_path = ["lib"]
    s.authors = ["Daniel DeLeo"]
    s.extensions = ["ext/scan_apache_logs/extconf.rb", "ext/scan_rails_logs/extconf.rb"]

    # ruby -rpp -e' pp `git ls-files`.split("\n") '
    s.files = `git ls-files`.split("\n").reject {|f| f =~ /git/}
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

desc "outputs a list of files suitable for use with the gemspec"
task :list_files do
  sh %q{ruby -rpp -e' pp `git ls-files`.split("\n").reject {|f| f =~ /git/} '}
end


CLEAN.add ["ext/*/*.bundle", "ext/*/*.so", "ext/*/*.o"]
CLOBBER.add ["ext/*/Makefile", "ext/*/*.c"]

namespace :ext do
  desc "Installs the C extensions.  Usually requires root."
  task :install => :build do
    Dir.glob("ext/*/").each do |ext_dir|
      Dir.chdir(ext_dir) {sh "make install"}
    end
  end

  desc "Compiles the C extensions"
  task :build do |t|
    Dir.glob("ext/*/").each do |ext_dir|
      cd(ext_dir) {sh "make"}
    end
  end
  
  desc "Generates Makefiles with extconf/mkmf"
  task :makefiles
  
  FileList["ext/*/*.yy"].each do |flex_file|
    flex_generated_c = flex_file.ext("yy.c")
    file flex_generated_c => flex_file do |t|
      sh "flex -i -s -o #{flex_generated_c} #{flex_file}"
    end
    task :build => flex_generated_c
    file flex_file
  end
  
  FileList["ext/*/extconf.rb"].each do |extconf_file|
    extension_dir = extconf_file.sub("extconf.rb", '')
    makefile = extension_dir + "Makefile"
    file makefile => extconf_file do |t|
      Dir.chdir(extension_dir) {ruby "./extconf.rb"}
    end
    file extconf_file
    task :build => makefile
  end
  
  desc "Compiles Teeth::Scanner scanner definitions into flex scanner definition"
  task :scanners do
    FileList["scanners/*"].each do |scanner|
      ruby scanner
    end
  end
  
    
end

desc "deletes generated gem"
task :clobber_gem do
  FileList['pkg/*gem'].each { |gemfile| rm gemfile }
end
task :clobber => :clobber_gem