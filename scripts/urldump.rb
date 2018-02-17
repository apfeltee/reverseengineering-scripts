#!/usr/bin/ruby

require "uri"
require "cgi"
require "pp"
require "ostruct"
require "optparse"
#require "json"
#require "awesome_print"

AwesomePrint.defaults = {
  index:  false,
  indent: -4,
} if defined?(AwesomePrint)

def _unescape(string, encoding="UTF-8")
  str = string.tr('+', ' ').b.gsub(/((?:%[0-9a-fA-F]{2})+)/){|m|
    [m.delete('%')].pack('H*')
  }.force_encoding(encoding)
  if str.valid_encoding? then
    return str
  end
  return str.force_encoding(string.encoding)
end

def parse_query(str)
  ret = {}
  if not str.nil? then
    CGI.parse(str).each do |vkey, vval|
      if vval.length > 1 then
        ret[vkey] = vval.map(&CGI.method(:unescape))
      else
        ret[vkey] = ((vval.first == nil) ? nil : _unescape(vval.first))
      end
    end
  end
  return ret
end

module Printers
  extend self

  def normal(out, data)
    data.each do |name, value|
      out.printf("%-10s =>  ", name.to_s)
      if name == :query then
        out.puts("{")
        value.each { |qn, qv|
          out.printf("  %p = ", qn)
          if qv.is_a?(Array) then
            out << "[\n" << qv.map{|v| sprintf("    %p", v)}.join(",\n") << "\n  ]"
          else
            out.printf("%p", qv)
          end
          out.printf("\n")
        }
        out.puts("}")
      else
        out.printf("%p", value)
      end
      out.puts
    end
  end

  if defined?(JSON) then
    def json(out, data)
      out.puts(JSON.pretty_generate(data))
    end
  end

  if defined?(AwesomePrint) then
    def awesome(out, data)
      out.puts(data.awesome_inspect)
    end
  end
end


def urldump(str, options)
  url = URI.parse(str)
  data = Hash({
    scheme: url.scheme,
    userinfo: url.userinfo,
    hostname: url.hostname,
    port: url.port,
    path: url.path,
    fragment: url.fragment,
    query: parse_query(url.query),
  }).select{|k, v| not v.nil?}
  if options.wanted.empty? then
    Printers.send(options.printer, $stdout, data)
  else
    if options.wanted.length > 1 then
      options.wanted.each_with_index do |w, i|
        v = data[w.to_sym]
        if v then
          $stdout.printf("%s=%p", w, v)
          if ((i + 1) != options.wanted.length) then
            $stdout.write(" ")
          end
        end
      end
    else
      v = data[options.wanted.first.to_sym]
      $stdout.puts(v) unless v.nil?
    end
  end
end

begin
  wants = %w(port hostname path query scheme user password)
  options = OpenStruct.new(printer: "normal", wanted: [])
  prs = OptionParser.new {|prs|
    prs.on("-p<name>", "--print-as=<name>", "Use <name> as output type"){|name|
      options.printer = name
      if not Printers.respond_to?(options.printer.to_sym) then
        $stderr.puts("error: output type #{name.dump} is unknown")
        exit
      end
    }
    #prs.on("-p", "--port", "print port, if any"){|_|
    #  options.wanted.push(:port)
    #}
    #prs.on("-h", "--hostname", "print hostname, if any")
    wants.each do |w|
      prs.on(nil, "--#{w}", "print #{w}, if any"){|_|
        options.wanted.push(w)
      }
    end
  }
  prs.parse!
  if ARGV.empty? then
    if not $stdin.tty? then
      urldump($stdin.read.strip, options)
    else
      $stderr.puts(prs)
    end
  else
    ARGV.each do |arg|
      urldump(arg, options)
    end
  end
end
