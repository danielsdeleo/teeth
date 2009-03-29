require "erb"
module Teeth
  class ScannerError < StandardError
  end
  
  class InvalidExtensionDirectory < ScannerError
  end
  
  class Scanner
    TEMPLATE = File.dirname(__FILE__) + "/../templates/tokenizer.yy.erb"
    attr_reader :scanner_defns, :scanner_rules, :rdoc
    
    def initialize(name, ext_dir=nil)
      @scanner_base_name, @ext_dir = name, ext_dir
      @scanner_defns, @scanner_rules = ScannerDefinitionGroup.new, RuleStatementGroup.new
      ensure_ext_dir_exists if ext_dir
    end
    
    def scanner_name
      "scan_" + @scanner_base_name.to_s
    end
    
    def main_function_name
      "t_" + scanner_name
    end
    
    def init_function_name
      "Init_" + scanner_name
    end
    
    def function_prefix
      @scanner_base_name.to_s + "_yy"
    end
    
    def entry_point
      "scan_" + @scanner_base_name.to_s
    end
    
    def extconf
      'require "mkmf"' + "\n" + '$CFLAGS += " -Wall"' + "\n" + "create_makefile " +
      %Q|"teeth/#{scanner_name}", "./"\n| 
    end
    
    def rdoc=(rdoc_text)
      lines_of_rdoc_text = rdoc_text.split("\n").map { |line| " * " + line.strip}
      lines_of_rdoc_text.first[0] = "/"
      lines_of_rdoc_text[-1] = lines_of_rdoc_text.last + " */"
      @rdoc = lines_of_rdoc_text.join("\n")
    end
    
    def define(*args)
      @scanner_defns.add(*args)
    end
    
    def definitions
      yield @scanner_defns
    end
    
    def load_default_definitions_for(*defn_types)
      @scanner_defns.defaults_for(*defn_types)
    end
    
    def rule(*args)
      scanner_rules.add(*args)
    end
    
    def rules
      yield scanner_rules
    end
    
    def generate
      template = ERB.new(IO.read(TEMPLATE))
      scanner = self
      b = binding
      template.result(b)
    end
    
    def write!
      raise InvalidExtensionDirectory, "no extension directory specified" unless @ext_dir
      File.open(@ext_dir + "/extconf.rb", "w") do |extconf_rb|
        extconf_rb.write extconf
      end
      File.open(@ext_dir + "/" + scanner_name + ".yy", "w") do |scanner|
        scanner.write generate
      end
    end
    
    private
    
    def ensure_ext_dir_exists
      unless File.exist?(@ext_dir)
        Dir.mkdir @ext_dir
      end
    end
    
  end
  
  class ScannerDefinition
    attr_reader :name, :regex
    
    def initialize(name, regex, opts={})
      @name, @regex = name, regex
    end
    
    def scanner_code
      @name.to_s + " " + @regex
    end
    
  end
  
  class DuplicateDefinitionError < ScannerError
  end
  
  class InvalidDefaultDefinitionName < ScannerError
  end
  
  class ScannerDefinitionGroup < Array
    
    DEFAULT_DEFINITIONS = {}
    DEFAULT_DEFINITIONS[:whitespace] = [["WS",  '[[:space:]]'],
                                        ["NON_WS", "([a-z]|[0-9]|[:punct:])"]]
    DEFAULT_DEFINITIONS[:ip]    = [ ["IP4_OCT", "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"],
                                    ["HOST", '[a-z0-9][a-z0-9\-]*\.[a-z0-9][a-z0-9\-]*.[a-z0-9][a-z0-9\-\.]*[a-z]+(\:[0-9]+)?']]
    DEFAULT_DEFINITIONS[:time]  = [ ["WDAY", "mon|tue|wed|thu|fri|sat|sun"],
                                    ["MON", "jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec"],
                                    ["MDAY", "3[0-1]|[1-2][0-9]|0[1-9]"],
                                    ["HOUR", "2[0-3]|[0-1][0-9]"],
                                    ["MINSEC", "[0-5][0-9]|60"],
                                    ["YEAR", "[0-9][0-9][0-9][0-9]"],
                                    ["PLUSMINUS", '(\+|\-)']]
    DEFAULT_DEFINITIONS[:web]   = [ ["REL_URL", %q{(\/|\\\\|\.)[a-z0-9\._\~\-\/\?&;#=\%\:\+\[\]\\\\]*}],
                                    ["PROTO", "(http:|https:)"],
                                    ["ERR_LVL", "(emerg|alert|crit|err|error|warn|warning|notice|info|debug)"],
                                    ["HTTP_VERS", 'HTTP\/(1.0|1.1)'],
                                    ["HTTP_VERB", "(get|head|put|post|delete|trace|connect)"],
                                    ["HTTPCODE", "(100|101|20[0-6]|30[0-5]|307|40[0-9]|41[0-7]|50[0-5])"],
                                    ["BROWSER_STR", '\"(moz|msie|lynx).+\"']]

    def add(name, regex, options={})
      assert_defn_has_unique_name(name)
      push ScannerDefinition.new(name, regex, options)
    end
    
    def assert_defn_has_unique_name(name)
      if defn_names.include?(name.to_s)
        raise DuplicateDefinitionError, "a definition for #{name.to_s} has already been defined"
      end
    end
    
    def defn_names
      map { |defn_statement| defn_statement.name.to_s }
    end
    
    def method_missing(called_method_name, *args, &block)
      args[1] ||={}
      add(called_method_name, args[0], args[1])
    end
    
    def defaults_for(*default_types)
      default_types.each do |default_type|
        unless default_definitions = DEFAULT_DEFINITIONS[default_type]
          raise InvalidDefaultDefinitionName, "no default definitions found for #{default_type.to_s}"
        end
        default_definitions.each do |defn|
          begin
            add(defn.first, defn.last)
          rescue DuplicateDefinitionError
          end
        end
      end
    end
    
    
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
      "#{regex} {\n" + function_body + "}\n"
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
  
  class DuplicateRuleError < ScannerError
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