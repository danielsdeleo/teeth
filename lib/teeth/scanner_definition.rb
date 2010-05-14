module Teeth
  class DuplicateDefinitionError < ScannerError
  end
  
  class InvalidDefaultDefinitionName < ScannerError
  end
  
  class ScannerDefinitionArgumentError < ScannerError
  end
  
  class ScannerDefinition
    attr_reader :name, :regex
    
    def initialize(name, regex, opts={})
      if regex.kind_of?(Hash)
        regex, opts = nil, regex
      end
      @name, @regex, @start_condition = name, regex, opts[:start_condition]
      assert_valid_argument_combination
    end
    
    def scanner_code
      start_condition_string + @name.to_s + regex_to_s
    end
    
    def regex_to_s
      unless @regex.to_s == ""
        " " + @regex.to_s
      else
        ""
      end
    end
    
    def start_condition_string
      case @start_condition.to_s
      when /^inc/
        "%s "
      when /^exc/
        "%x "
      else
        ""
      end
    end
    
    private
    
    def assert_valid_argument_combination
      if @start_condition
        if @regex.to_s != "" # (nil or "").to_s == ""
          raise ScannerDefinitionArgumentError, "a scanner definition cannot define both a regex and start condition"
        end
      end
    end
    
  end
  
  class ScannerDefinitionGroup < Array
    
    DEFAULT_DEFINITIONS = {}
    DEFAULT_DEFINITIONS[:whitespace] = [["WS",  '[[:space:]]'],
                                        ["NON_WS", "([a-z]|[0-9]|[:punct:])"]]
    DEFAULT_DEFINITIONS[:ip]    = [ ["IP4_OCT", "[0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]"],
                                    ["HOST", '([a-z0-9][a-z0-9\-]*\.[a-z0-9][a-z0-9\-]*.[a-z0-9][a-z0-9\-\.]*[a-z]+(\:[0-9]+)?)|localhost']]
    DEFAULT_DEFINITIONS[:time]  = [ ["WDAY", "mon|tue|wed|thu|fri|sat|sun"],
                                    ["MON", "jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec"],
                                    ["MONTH_NUM", "0[1-9]|1[0-2]"],
                                    ["MDAY", "3[0-1]|[1-2][0-9]|0[1-9]"],
                                    ["HOUR", "2[0-3]|[0-1][0-9]"],
                                    ["MINSEC", "[0-5][0-9]|60"],
                                    ["YEAR", "[0-9][0-9][0-9][0-9]"],
                                    ["PLUSMINUS", '(\+|\-)']]
    DEFAULT_DEFINITIONS[:web]   = [ ["TIMING", %q{[0-9]+\.[0-9]+}],
                                    ["REL_URL", %q{(\/|\\\\|\.)[a-z0-9\._\~\-\/\?&;#=\%\:\+\[\]\\\\]*}],
                                    ["PROTO", "(http:|https:)"],
                                    ["ERR_LVL", "(emerg|alert|crit|err|error|warn|warning|notice|info|debug)"],
                                    ["HTTP_VERS", 'HTTP\/(1.0|1.1)'],
                                    ["HTTP_VERB", "(get|head|put|post|delete|trace|connect)"],
                                    ["HTTPCODE", "(100|101|20[0-6]|30[0-5]|307|40[0-9]|41[0-7]|50[0-5])"],
                                    ["BROWSER_STR", '\"(moz|msie|lynx|reconnoiter|pingdom)[^"]+\"']]

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
end