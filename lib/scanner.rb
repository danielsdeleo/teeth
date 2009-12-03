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
      'require "mkmf"' + "\n" + '$CFLAGS += " -Wall"' + "\n" + 
      'have_library("uuid", "uuid_generate_time")' + "\n" +
      "create_makefile " +
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
  
end