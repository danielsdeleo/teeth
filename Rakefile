require "spec/rake/spectask"

desc "Run all of the specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"spec/spec.opts\""]
end

namespace :spec do

  desc "Generate HTML report for failing examples"
  Spec::Rake::SpecTask.new('report') do |t|
    t.spec_files = FileList['failing_examples/**/*.rb']
    t.spec_opts = ["--format", "html:doc/tools/reports/failing_examples.html", "--diff", '--options', '"spec/spec.opts"']
    t.fail_on_error = false
  end
  
end

desc "Installs the C extensions.  Usually requires root."
task :install => :ext do
  cd "ext"
  sh "make install"
  cd ".."
end

desc "Compiles the C extensions"
task :ext => ["ext/Makefile", "ext/tokenize_apache_logs.yy.c"] do
  cd "ext"
  sh "make"
  cd ".."
end

file 'ext/tokenize_apache_logs.yy.c' => 'ext/tokenize_apache_logs.yy' do |t|
  sh "flex -i -s -o ext/tokenize_apache_logs.yy.c ext/tokenize_apache_logs.yy"    
end

file 'ext/tokenize_apache_logs.yy'

file "ext/Makefile" do
  cd "ext"
  ruby "extconf.rb"
  cd ".."
end
