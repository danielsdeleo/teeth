require File.dirname(__FILE__) + '/../spec_helper'

describe RuleStatement do
  
  it "should generate a rule to short circuit scanner processing when given option :skip_line => true" do
    rs = RuleStatement.new :rails_session_id_start, '{WS}*Session ID":"', :skip_line => true
    expected = 
%q|{WS}*Session ID":" {
  return EOF_KVPAIR;
}|
    rs.scanner_code.should == expected
  end

  it "should use strip_ends(yytext) in the rule when given option :strip_ends => true" do
    rs = RuleStatement.new :browser_string, '{BROWSER_STR}', :strip_ends => true
    expected = 
%q|{BROWSER_STR} {
  KVPAIR browser_string = {"browser_string", strip_ends(yytext)};
  return browser_string;
}|
    rs.scanner_code.should == expected
  end
  
end

describe RuleStatementGroup do
  
  before(:each) do
    @statement_group = RuleStatementGroup.new
  end
  
  it "should reject duplicate rule definitions" do
    @statement_group.add :explode_on_2nd_try, '{WS}'
    lambda {@statement_group.add :explode_on_2nd_try, '{WS}'}.should raise_error DuplicateRuleError
  end
  
  it "should use method missing magic to define rules with sugary syntax" do
    @statement_group.http_version "{HTTP_VERSION}"
    @statement_group.first.should == RuleStatement.new(:http_version, "{HTTP_VERSION}")
  end
  
  
end