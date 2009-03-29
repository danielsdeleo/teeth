require File.dirname(__FILE__) + '/../spec_helper'
require "fileutils"
include FileUtils
describe Scanner do
  TEST_EXT_DIR = File.dirname(__FILE__) + "/test_ext_dir"
  
IPV4_ACTION_TEXT = 
%q|{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT} {
  KVPAIR ipv4_addr = {"ipv4_addr", yytext};
  return ipv4_addr;
}
| 
  
  def clean_test_scanner_dir
    rm_rf TEST_EXT_DIR
  end
  
  before(:all) do
    clean_test_scanner_dir
  end
  
  before(:each) do
    @scanner = Scanner.new(:rspec_awesome)
  end
  
  after(:all) do
    clean_test_scanner_dir
  end
  
  it "should generate the code for an extconf file" do
    expected = 'require "mkmf"' + "\n" + '$CFLAGS += " -Wall"' + "\n" +
    'create_makefile "teeth/scan_rspec_awesome", "./"' + "\n"
    @scanner.extconf.should == expected
  end
  
  it "should create a new directory for the extension" do
    scanner = Scanner.new(:rspec_awesomeness, TEST_EXT_DIR)
    File.exist?(TEST_EXT_DIR).should be_true
  end
  
  it "should initialize with a name for for the tokenizer function and method" do
    scanner = Scanner.new(:rails_dev_logs)
    scanner.scanner_name.should == "scan_rails_dev_logs"
    scanner.main_function_name.should == "t_scan_rails_dev_logs"
    scanner.init_function_name.should == "Init_scan_rails_dev_logs"
    scanner.function_prefix.should == "rails_dev_logs_yy"
    scanner.entry_point.should == "scan_rails_dev_logs"
  end
  
  it "should format rdoc for the C function which corresponds to the ruby method" do
    @scanner.rdoc = <<-RDOC
    Premature optimization
    is the root of
    all evil.
    RDOC
    @scanner.rdoc.should == "/* Premature optimization\n * is the root of\n * all evil. */"
  end
  
  it "should accept a ``global'' option to include UUID generation or not"
  
  it "should store scanner definitions" do
    @scanner.define "IP4_OCTET", "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
    @scanner.scanner_defns.first.scanner_code.should == "IP4_OCTET [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
  end
  
  it "should accept definitions in a block" do
    @scanner.definitions do |d|
      d.add "IP4_OCTET", "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
      d.add "WDAY", "mon|tue|wed|thu|fri|sat|sun"
    end
    expected = ["IP4_OCTET [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"]
    expected << "WDAY mon|tue|wed|thu|fri|sat|sun"
    @scanner.scanner_defns.map { |defn| defn.scanner_code}.should == expected
  end
  
  it "should use method missing magic for sugary definitions within a block" do
    @scanner.definitions do |define|
      define.IP4_OCTET "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
    end
    @scanner.scanner_defns.first.scanner_code.should == "IP4_OCTET [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
  end
  
  it "should reject duplicate definitions" do
    @scanner.define("WS",  '[\000-\s]')
    lambda { @scanner.define("WS",  '[\000-\s]') }.should raise_error DuplicateDefinitionError
  end
  
  it "should add a default set of definitions" do
    @scanner.load_default_definitions_for(:whitespace, :ip)
    @scanner.scanner_defns.map { |d| d.name.to_s }.should == ["WS", "NON_WS", "IP4_OCT", "HOST"]
  end
  
  it "should explode if requested to add default definitions that don't exist" do
    lambda { @scanner.load_default_definitions_for(:foobarbaz) }.should raise_error InvalidDefaultDefinitionName
  end
  
  it "should not error if conflicting user definitions exist when loading defaults" do
    @scanner.define "WS", '[\000-\s]'
    lambda {@scanner.load_default_definitions_for(:whitespace)}.should_not raise_error
  end
  
  it "should not override user definitions when loading defaults" do
    @scanner.define "WS", "a-telltale-sign"
    @scanner.load_default_definitions_for(:whitespace)
    @scanner.scanner_defns.reject { |defn| defn.name != "WS" }.first.regex.should == "a-telltale-sign"
  end
  
  it "should generate scanner rule statements, defaulting to returning a KVPAIR of rule name, yytext" do
    @scanner.rule :ipv4_addr, '{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}'
    @scanner.scanner_rules.first.scanner_code.should == IPV4_ACTION_TEXT
  end
  
  it "should accept rule statments in a block" do
    @scanner.rules do |rules|
      rules.add  :ipv4_addr, '{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}'
    end
    @scanner.scanner_rules.first.scanner_code.should == IPV4_ACTION_TEXT
  end
  
  it "should generate a rule to short circuit scanner processing when given option :skip_line => true" do
    @scanner.rule :rails_session_id_start, '{WS}*Session ID":"', :skip_line => true
    expected = 
%q|{WS}*Session ID":" {
  return EOF_KVPAIR;
}
|
    @scanner.scanner_rules.first.scanner_code.should == expected
  end
  
  it "should use strip_ends(yytext) in the rule when given option :strip_ends => true" do
    @scanner.rule :browser_string, '{BROWSER_STR}', :strip_ends => true
    expected = 
%q|{BROWSER_STR} {
  KVPAIR browser_string = {"browser_string", strip_ends(yytext)};
  return browser_string;
}
|
    @scanner.scanner_rules.first.scanner_code.should == expected
  end
  
  it "should reject duplicate rule definitions" do
    @scanner.rule :explode_on_2nd_try, '{WS}'
    lambda {@scanner.rule :explode_on_2nd_try, '{WS}'}.should raise_error DuplicateRuleError
  end
  
  it "should use method missing magic to accept rules within a block" do
    @scanner.rules do |rule|
      rule.http_version "{HTTP_VERSION}"
    end
    @scanner.scanner_rules.first.should == RuleStatement.new(:http_version, "{HTTP_VERSION}")
  end
  
  it "should render a scanner scanner from the template" do
    @scanner.load_default_definitions_for(:whitespace, :ip, :web)
    @scanner.rules do |rule|
      rule.ipv4_addr '{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}'
      rule.relative_url '{REL_URL}'
    end
    result = @scanner.generate
    # real test is if scanner compiles and passes its own tests
    result.should_not match(Regexp.new(Regexp.quote '<%='))
  end
  
  it "should write the scanner and extconf files in the ext directory" do
    scanner = Scanner.new(:rspec_awesomeness, TEST_EXT_DIR)
    scanner.load_default_definitions_for(:whitespace, :ip, :web)
    scanner.rules do |rule|
      rule.ipv4_addr '{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}'
      rule.relative_url '{REL_URL}'
    end
    scanner.write!
    File.exist?(TEST_EXT_DIR + "/extconf.rb").should be_true
    File.exist?(TEST_EXT_DIR + "/scan_rspec_awesomeness.yy").should be_true
  end
  
end