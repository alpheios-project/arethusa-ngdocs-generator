#!/usr/bin/env ruby

require_relative 'parser'
require_relative 'definition'

def error(message)
  puts message
  exit
end

def file_list(path, list)
  if File.directory?(path)
    Dir.glob(File.join(path, '*')).each { |p| file_list(p, list)}
  else
    list << path
  end
end

if __FILE__ == $0
  path = ARGV[0]
  error("Need a path to a file or a directory to run") unless path

  absolute = File.expand_path(path, __FILE__)

  error("No file at #{absolute}") unless File.exists?(absolute)
  files = []
  file_list(absolute, files)
  annotations = files.count { |file| Parser.new(file).annotate }

  puts "#{annotations} file(s) annotated!"
end
