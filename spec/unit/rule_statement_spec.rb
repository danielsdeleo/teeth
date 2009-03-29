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
  
  it "should include a call to the BEGIN() macro if given the :begin option" do
    rs = RuleStatement.new :start_special_state, '{SPECIAL_STATE_REGEX}', :begin => "SPECIAL_STATE"
    expected = 
%q|{SPECIAL_STATE_REGEX} {
  BEGIN(SPECIAL_STATE);
  KVPAIR start_special_state = {"start_special_state", yytext};
  return start_special_state;
}|
    rs.scanner_code.should == expected
  end
  
  it "should not include any C code if given :ignore => true" do
    rs = RuleStatement.new :catchall_rule_for_special_state, '<SPECIAL_STATE>{CATCHALL}', :ignore => true
    expected = %q|<SPECIAL_STATE>{CATCHALL}|
    rs.scanner_code.should == expected
  end
  
end

describe RuleStatementGroup do
  
  before(:each) do
    @statement_group = RuleStatementGroup.new
  end
  
  it "should not reject duplicate rule definitions" do
    @statement_group.add :explode_on_2nd_try, '{WS}'
    lambda {@statement_group.add :explode_on_2nd_try, '{WS}'}.should_not raise_error DuplicateRuleError
  end
  
  it "should use method missing magic to define rules with sugary syntax" do
    @statement_group.http_version "{HTTP_VERSION}"
    @statement_group.first.should == RuleStatement.new(:http_version, "{HTTP_VERSION}")
  end
  
  
end