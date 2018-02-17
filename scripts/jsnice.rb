#!/usr/bin/ruby

require 'pp'
require 'json'
require 'uri'
require 'net/http'

class JSNice
  def initialize
    @uri = URI.parse("http://www.jsnice.org/")
    @settings =
    {
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
      $stderr.puts("received #{body.length} bytes of code")
      @result = body
    else
      $stderr.puts("something failed?")
      exit
    end
  end

  def post_file(path)
    return post(File.read(path))
  end

  def json
    return JSON.load(@result)
  end

  def result
    return json["js"]
  end
end

begin
  jsn = JSNice.new
  if ARGV.length > 0 then
    ARGV.each do |path|
      jsn.post_file(path)
    end
  else
    jsn.post($stdin.read)
  end
  puts(jsn.result)
end

