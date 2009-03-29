require File.dirname(__FILE__) + '/../spec_helper'

require File.dirname(__FILE__) + '/../spec_helper'

describe ScannerDefinition do
  
  it "should generate text for flex definitions" do
    defn = ScannerDefinition.new "IP4_OCTET", "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
    defn.scanner_code.should == "IP4_OCTET [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
  end
  
  it "should complain if given a :start_condition option and a regex" do
    fail = lambda {ScannerDefinition.new "FAIL", "FAIL", :start_condition => :inclusive}
    fail.should raise_error ScannerDefinitionArgumentError
  end
  
  it "should add %s to the beginning of the definition for option :start_condition => :inclusive" do
    defn = ScannerDefinition.new "SPECIAL_STATE", :start_condition => :inclusive
    defn.scanner_code.should == "%s SPECIAL_STATE"
  end
  
end

describe ScannerDefinitionGroup do
  before(:each) do
    @defn_group = ScannerDefinitionGroup.new
  end
  
  it "should hold multiple definitions" do
    @defn_group.add "IP4_OCTET", "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
    @defn_group.add "WDAY", "mon|tue|wed|thu|fri|sat|sun"
    @defn_group.should have(2).definitions
  end
  
  it "should use method missing magic for sugary definitions" do
    @defn_group.IP4_OCTET "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
    @defn_group.scanner_defns.first.scanner_code.should == "IP4_OCTET [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"
  end
  
  it "should reject duplicate definitions" do
    @defn_group.add("WS",  '[\000-\s]')
    lambda { @defn_group.add("WS",  '[\000-\s]') }.should raise_error DuplicateDefinitionError
  end
  
  it "should add a default set of definitions" do
    @defn_group.defaults_for(:whitespace, :ip)
    @defn_group.defn_names.should == ["WS", "NON_WS", "IP4_OCT", "HOST"]
  end
  
  it "should explode if requested to add default definitions that don't exist" do
    lambda { @defn_group.defaults_for(:foobarbaz) }.should raise_error InvalidDefaultDefinitionName
  end
  
  it "should not error if conflicting user definitions exist when loading defaults" do
    @defn_group.add "WS", '[\000-\s]'
    lambda {@defn_group.load_default_definitions_for(:whitespace)}.should_not raise_error
  end
  
  it "should not override user definitions when loading defaults" do
    @defn_group.add "WS", "a-telltale-sign"
    @defn_group.load_default_definitions_for(:whitespace)
    @defn_group.reject { |defn| defn.name != "WS" }.first.regex.should == "a-telltale-sign"
  end
  
end