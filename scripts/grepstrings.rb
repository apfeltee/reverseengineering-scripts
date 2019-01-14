#!/usr/bin/ruby

require "optparse"

#STRING_REGEXP = Regexp.new("(\\\"(.*?)\\\"|\'(.*?)\')")
#STRING_REGEXP = /(?=["'])(?:"[^"\\]*(?:\\[\s\S][^"\\]*)*"|'[^'\\]*(?:\\[\s\S][^'\\]*)*')/
STRING_REGEXP = /(["'])((?:(?!\1)[^\\]|(?:\\\\)*\\[^\\])*)\1/


def ispipe?
  return (not $stdin.tty?)
end

class String
  def isprint?
    return (self =~ /[^[:print:]]/)
  end
end

class GrepStrings
  def initialize(**options)
    @options = options
    @seen = []
  end

  def verbose(fmt, *args)
    str = if args.empty? then fmt else sprintf(fmt, *args) end
    if @options[:verbose] then
      $stderr.printf("verbose: %s\n", str)
    end
  end

  def do_io(io, filename)
    io.each_line do |line|
      line.scrub.scan(STRING_REGEXP).each do |match|
        #p match
        #data = match.shift
        #raw = match.shift
        #rest = match
        quot = match[0]
        realraw = match[1]
        raw = (quot + realraw + quot)
        data = realraw #.gsub(/^["']/, "").gsub(/["']$/, "")
        

        if not raw.nil? then
          if @options[:printonly] then
            next if (not raw.ascii_only?)
          end
          if @options[:unique] then
            # this is kept deliberately separately to improve performance
            if @options[:nocase] then
              next if @seen.include?(raw)
              @seen.push(raw)
            else
              sraw = raw.downcase
              next if @seen.include?(sraw)
              @seen.push(sraw)
            end
          end
          if @options[:printfilename] then
            $stdout.printf("%s: ", filename)
          end
          $stdout.puts(@options[:printraw] ? raw : data )
        end
      end
    end
  end
end

begin
  $stdout.sync = true
  options = {
    unique: true,
    nocase: false,
    printonly: true,
    printraw: false,
    printfilename: false,
    verbose: false,
  }
  prs = OptionParser.new{|prs|
    prs.on("-u", "--[no-]unique", "print only unique strings"){|v|
      options[:unique] = v
    }
    prs.on("-i", "--[no-]case-insensitive", "ignore case when -u is specified (implies '-u')"){|v|
      options[:unique] = true
      options[:nocase] = v
    }
    prs.on("-r", "--[no-]print-raw", "print raw (quoted) string, instead of content only"){|v|
      options[:printraw] = v
    }
    prs.on("-p", "--[no-]printable-only", "print only ascii strings"){|v|
      options[:printonly] = v
    }
    prs.on("-v", "--verbose", "enable verbose messages"){|v|
      options[:verbose] = true
    }
    prs.on("-f", "--printfilename", "print filename as well"){|v|
      options[:printfilename] = true
    }
  }
  prs.parse!
  grep = GrepStrings.new(**options)
  if ispipe? && ARGV.empty? then
    grep.do_io($stdin, "<stdin>")
  else
    if ARGV.empty? then
      $stderr.puts("ERROR: no input files given, and no pipe present!")
      $stderr.puts(prs.help)
      exit(1)
    else
      ARGV.each do |filename|
        File.open(filename, "rb") do |fh|
          grep.verbose("processing %p ...", filename)
          grep.do_io(fh, filename)
        end
      end
    end
  end
end
