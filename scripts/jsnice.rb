#!/usr/bin/ruby


require 'pp'
require 'json'
require 'uri'
require 'net/http'
require 'ostruct'
require 'optparse'

=begin
fetch("http://jsnice.org/beautify?pretty=1&rename=1&types=1&packers=1&transpile=1&suggest=0", {"credentials":"omit","headers":{},"referrer":"http://jsnice.org/","referrerPolicy":"no-referrer-when-downgrade","body":"// Put your JavaScript here that you want to rename, deobfuscate,\n// or infer types for:\nfunction chunkData(e, t) {\n  var n = [];\n  var r = e.length;\n  var i = 0;\n  for (; i < r; i += t) {\n    if (i + t < r) {\n      n.push(e.substring(i, i + t));\n    } else {\n      n.push(e.substring(i, r));\n    }\n  }\n  return n;\n}\n// You can also use some ES6 features.\nconst get = (a,b) => a.getElementById(b);\n\n","method":"POST","mode":"cors"});
=end

class JSNice
  def initialize
    @uri = URI.parse("http://www.jsnice.org/")
    @settings =
    {
      'transpile' => 0,
      'strict' => 0,
      'pretty' => 1,
      'types' => 1,
      'rename' => 1,
      'language_in' => 'es7',
    }
  end

  def set(key, value)
    @settings[key] = value
    pp ['@settings', @settings]
  end

  def setbool(key, val)
    set(key, val ? 1 : 0)
  end

  def pretty=(val)
    setbool('pretty', val)
  end

  def rename=(val)
    setbool('rename', val)
  end

  def types=(val)
    setbool('types', val)
  end

  def suggest=(val)
    setbool('suggest', val)
  end

  def queryfy(params)
    array = params.zip.map do |pairs|
      pairs = pairs.shift
      normalized = pairs.map do |val|
        val.to_s
      end
      next normalized.join("=")
    end
    return array.join("&")
  end

  def post(data)
    $stderr.puts("options: #{@settings.inspect}")
    $stderr.puts("sending #{data.length} bytes of code...")
    path = ("/beautify?" + queryfy(@settings))
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.read_timeout = 5000000
    if response = http.post(path, data,
    {
      'Content-Type'     => 'application/x-www-form-urlencoded; charset=UTF-8',
      'Origin'           => 'http://jsnice.org',
      'X-Requested-With' => 'XMLHttpRequest',
      'User-Agent'       => 'Mozilla/5.0 (Windows NT 6.1;) Gecko/20100101 Firefox/24.0',
    }) then
      body = response.body
      hdrs = response.to_hash
      $stderr.printf("received %d bytes of code\n", body.length)
      @result = JSON.load(body)
      jsres = @result["js"].to_s
      if (jsres.match(/^\/\/\sError\scompiling\sinput/)) || (jsres.match(/ERROR!.*failed/)) then
        raise "jsnice seemed not to be able to parse input:\n#{@result["js"]}"
      end
    else
      $stderr.puts("something failed?")
      exit
    end
  end

  def post_file(path)
    return post(File.read(path))
  end

  def json
    return @result
  end

  def result
    return @result["js"]
  end
end

def dofile(path, opts)
  jsn = JSNice.new
  jsn.post_file(path)
  if opts.inplace then
    File.open(path, "wb") do |fh|
      fh.write(jsn.result)
    end
  else
    $stdout.puts(jsn.result)
  end
end

begin
  opts = OpenStruct.new
  (prs=OptionParser.new{|prs|
    prs.on("-i", "--inplace"){|_|
      opts.inplace = true
    }
  }).parse!
  
  if ARGV.length > 0 then
    ARGV.each do |path|
      #jsn.post_file(path)
      if opts.inplace then
        $stderr.printf("will modify %p in-place\n", path)
      end
      dofile(path, opts)
    end
  else
    jsn = JSNice.new
    jsn.post($stdin.read)
    puts(jsn.result)
    p jsn.json
  end
end

