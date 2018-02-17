#!/usr/bin/ruby --disable-gems

require "optparse"
require "uri"

## schemes that also make sense to search for:
# "data:" for data-uris. often abused, sort of.
# "file:" for local files. also often abused.


VALID_SCHEMES = %w(
  ftp sftp http https mailto
  git chrome chrome-extension
  udp tcp
)

class URLGrep
  attr_accessor :validschemes

  def initialize(opts)
    @options = opts
    @validschemes = VALID_SCHEMES
    @uris = []
  end

  def do_file(path)
    if File.file?(path) then
      File.open(path, "rb") do |fh|
        iter_io(path, fh)
      end
    else
      $stderr.puts("urlgrep: not a file: #{path.dump}")
    end
  end

  def do_stdin
    iter_io("<stdin>", $stdin)
  end

  def iter_io(path, io)
    ppath = File.basename(path)
    io.each_line do |line|
      URI.extract(line.scrub, @validschemes) do |uri|
        if ((@options[:only_uniques] == true) && (@uris.include?(uri))) then
          next
        end
        print_result(path, uri)
        @uris.push(uri)
      end
    end
  end

  def print_result(path, res)
    printme = (@options[:dump] ? res.dump : res)
    if @options[:printfilename] then
      $stdout.printf("%s: ", path)
    end
    $stdout.printf("%s\n", printme)
  end
end

begin
  $stdin.sync = true
  $stdout.sync = true
  options = {dump: false, only_uniques: true}
  prs = OptionParser.new {|prs|
    prs.on("-u", "--[no-]unique", "print only unique URIs"){|v|
      options[:only_uniques] = v
    }
    prs.on("-d", "--[no-]dump", "use String#dump before printing each URI"){|v|
      options[:dump] = v
    }
    prs.on("-f", "--[no-]filename", "print filename before each line"){|v|
      options[:printfilename] = v
    }
  }
  prs.parse!
  ug = URLGrep.new(options)
  if ARGV.empty? then
    ug.do_stdin
  else
    ARGV.each do |file|
      ug.do_file(file)
    end
  end
end
