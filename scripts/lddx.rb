#!/usr/bin/ruby

require "optparse"
require "pedump"
require "colorize"

def make_paths
  envpaths = ["."] + ENV["PATH"].split(":")
  # probably would need to figure out if
  # we're on cygwin, and also if it's 32bit or 64bit, since
  # that actually matters a lot
  if true then
    if ENV["ORIGINAL_PATH"] then
      envpaths += ENV["ORIGINAL_PATH"].split(":")
    end
    envpaths.map!{|path|
      if path.start_with?("/cygdrive") then
        path.gsub(/^\/cygdrive\/(.)(.*)/, '\1:\2')
      else
        path
      end
    }
    envpaths.push("c:/windows/system32", "c:/windows/syswow64")
  end
  return envpaths
end

def guesspath(dll, envpaths)
  envpaths.each do |dir|
    path = File.join(dir, dll)
    if File.file?(path) then
      return path
    end
  end
  return nil
end

class LDDx
  def initialize(**opts)
    @seen = []
    @recursecache = []
    @opts = opts
    @envpaths = make_paths
  end

  def verbose(fmt, *args)
    if @opts[:verbose] then
      str = if args.empty? then fmt else sprintf(fmt, *args) end
      $stderr.puts("lddx:verbose: #{str}")
    end
  end

  def do_ldd(filename)
    recurse = []
    basename = File.basename(filename).downcase
    if @seen.include?(basename) then
      return
    end
    @seen.push(basename)
    begin
      verbose("opening %p ...", filename)
      File.open(filename, "rb") do |fh|
        pe = PEdump.new(fh)
        imports = pe.imports
        if imports.empty? then
          verbose("file has no imports, nothing to do")
          return
        end
        tmp = []
        longest = imports.map{|ip| ip.module_name }.max_by(&:length)
        verbose("%p has %d imports", filename, imports.length)
        pad = (if longest.nil? then 0 else longest.length end)
        pe.imports.each do |imp|
          name = imp.module_name
          ofs = imp.OriginalFirstThunk # i think?? idk
          path = guesspath(name, @envpaths)
          strpath = (path || "(not found)".colorize(:red))
          if not @recursecache.include?(File.basename(strpath).downcase) then
            tmp.push([name, ofs, path, strpath])
          end
          if @opts[:recursive] then
            if path then
              @recursecache.push(path.downcase)
            end
          end
          recurse.push(path) if path
        end
        puts("#{filename}:")
        tmp.each do |info|
          name, ofs, path, strpath = info
          if @opts[:lddformat] then
            ofsfmt = sprintf("0x%X", ofs).colorize(:blue)
            printf("    %-#{pad}s => %s (%s)\n", name, strpath, ofsfmt)
          else
            strpath = (path || name)
            printf("  (0x%X) %s%s\n", ofs, strpath, (path == nil ? " (not found)" : ""))
          end
        end
      end
    rescue => err
      $stdout.puts("lddx: error reading #{filename.dump}: (#{err.class}) #{err.message}")
      $stdout.puts("backtrace:")
      err.backtrace.each do |line|
        $stdout.puts("   #{line}")
      end
    end
    if @opts[:recursive] then
      recurse.each do |r|
        if not @recursecache.include?(r) then
          do_ldd(r)
        end
      end
    end
  end
end

begin
  $stdout.sync = true
  if not $stdout.tty? then
    String.disable_colorization = true
  end
  opts = {lddformat: true}
  prs = OptionParser.new{|prs|
    prs.on("-v", "--verbose", "toggle verbose output"){|v|
      opts[:verbose] = v
    }
    prs.on("-r", "--[no-]recursive", "perform lddx on every module name"){|v|
      opts[:recursive] = v
    }
    prs.on(nil, "--[no-]lddformat", "use traditional 'ldd' style output"){|v|
      opts[:lddformat] = v
    }
  }
  prs.parse!
  if ARGV.empty? then
    $stderr.puts("no file arguments given!")
    $stderr.puts(prs.help)
  else
    ctx = LDDx.new(**opts)
    ARGV.each do |arg|
      ctx.do_ldd(arg)
    end
  end
end
