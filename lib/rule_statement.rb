module Teeth
  
  class DuplicateRuleError < ScannerError
  end

  class RuleStatement
    attr_reader :name, :regex, :strip_ends, :skip_line
    
    def initialize(name, regex, options={})
      @name, @regex = name, regex
      @strip_ends, @skip_line = options[:strip_ends], options[:skip_line]
    end
    
    def ==(other)
      other.kind_of?(RuleStatement) && other.name == name && other.regex == regex
    end
    
    def scanner_code
      "#{regex} {\n" + function_body + "}"
    end
        
    def function_body
      if skip_line
        "  return EOF_KVPAIR;\n"
      else
        "  KVPAIR #{name.to_s} = {\"#{name.to_s}\", #{yytext_statement}};\n" +
        "  return #{name.to_s};\n"
      end
    end
    
    def yytext_statement
      strip_ends ? "strip_ends(yytext)" : "yytext"
    end
    
  end
  
  class RuleStatementGroup < Array
    
    def add(name, regex, options={})
      assert_rule_has_unique_name(name)
      push RuleStatement.new(name, regex, options)
    end
    
    def assert_rule_has_unique_name(name)
      if rule_names.include?(name.to_s)
        raise DuplicateRuleError, "a rule named #{name} has already been defined"
      end
    end
    
    def rule_names
      map { |rule_statement| rule_statement.name.to_s }
    end
    
    def method_missing(called_method_name, *args, &block)
      args[1] ||={}
      add(called_method_name, args[0], args[1])
    end
    
  end
end