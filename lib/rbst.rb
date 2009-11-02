require 'open4'

class RbST
  
  # Takes a string or file path plus any additional options and converts the input.
  def self.convert(*args)
    new(*args).convert
  end
  
  # Print LaTeX-Specific Options, General Docutils Options and reStructuredText Parser Options.
  def self.latex_options
    new.print_options(:latex)
  end
  
  # Print HTML-Specific Options, General Docutils Options and reStructuredText Parser Options.
  def self.html_options
    new.print_options(:html)
  end
  
  # Takes a string or file path plus any additional options and creates a new converter object.
  def initialize(*args)
    target = args.shift
    @target  = File.exists?(target) ? File.read(target) : target rescue target
    @options = args
  end

  def convert(writer = :html) # :nodoc:
    execute "python #{RbST.executable(writer)}" + convert_options
  end
  alias_method :to_s, :convert
  
  # Converts the object's input to HTML.
  def to_html
    convert(:html)
  end
  
  # Converts the object's input to LaTeX.
  def to_latex
    convert(:latex)
  end
  
  def print_options(format) # :nodoc:
    help = execute("python #{RbST.executable(format)} --help")
    help.gsub!(/(\-\-)([A-Za-z0-9]+)([=|\s])/, ':\2\3')
    help.gsub!(/(\-\-)([\w|\-]+)(\n)?[^$|^=|\]]?/, '\'\2\'\3')
    help.gsub!(/\=/, ' => ')
    help.gsub!(/([^\w])\-(\w)([^\w])/, '\1:\2\1')
    help.gsub!(/(:\w) </, '\1 => <')
    puts help
  end
  
private
  
  def self.executable(writer = :html)
    File.join(File.dirname(__FILE__), "rst2parts", "rst2#{writer}.py")
  end
  
  def execute(command)
    output = ''
    Open4::popen4(command) do |pid, stdin, stdout, stderr| 
      stdin.puts @target 
      stdin.close
      output = stdout.read.strip 
    end
    output
  end

  def convert_options
    @options.inject('') do |string, opt|
      string + if opt.respond_to?(:each_pair)
        opt.inject('') do |s, (flag, val)|
          s + if flag.to_s.length == 1
            " -#{flag} #{val}"
          else
            " --#{flag.to_s.gsub(/_/, '-')}=#{val}"
          end
        end
      else
        opt.to_s.length == 1 ? " -#{opt}" : " --#{opt.to_s.gsub(/_/, '-')}"
      end
    end
  end
end