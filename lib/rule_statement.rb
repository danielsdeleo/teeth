module Teeth
  
  class DuplicateRuleError < ScannerError
  end

  class RuleStatement
    attr_reader :name, :regex, :strip_ends, :skip_line, :begin
    
    def initialize(name, regex, options={})
      @name, @regex = name, regex
      @strip_ends, @skip_line, @begin = options[:strip_ends], options[:skip_line], options[:begin]
      @ignore = options[:ignore]
    end
    
    def ==(other)
      other.kind_of?(RuleStatement) && other.name == name && other.regex == regex
    end
    
    def scanner_code
      if @ignore
        regex
      else
        "#{regex} {\n" + function_body + "}"
      end
    end
        
    def function_body
      code = ""
      code += "  BEGIN(#{@begin});\n" if @begin
      if skip_line
        code += "  return EOF_KVPAIR;\n"
      else
        code += "  KVPAIR #{name.to_s} = {\"#{name.to_s}\", #{yytext_statement}};\n" +
        "  return #{name.to_s};\n"
      end
      code
    end
    
    def yytext_statement
      strip_ends ? "strip_ends(yytext)" : "yytext"
    end
    
  end
  
  class RuleStatementGroup < Array
    
    def add(name, regex, options={})
      push RuleStatement.new(name, regex, options)
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