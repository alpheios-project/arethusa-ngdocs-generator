#!/usr/bin/env ruby

class Parser
  def initialize(file)
    @file = file
    @lines = File.read(file).split("\n");
  end

  def annotate
    @lines.each_with_index do |line, i|
      return if line =~ /@ngdoc/
      next unless @definition = get_definition(line, i)
      break;
    end

    return unless @definition

    i = @definition.line_no

    unless @lines[i].match(/function.\(\) {/)
      while (next_line = @lines[i + 1]) && next_line !~ /^\s*function/
        dependency = next_line.scan(/[\$\w]/).join
        @definition.add_dependency(dependency)
        i += 1
      end
    end

    annotated_file = @definition.annotate(@lines)
    File.write(@file, annotated_file)
  end

  private

  def get_definition(line, line_no)
     m = line.match(def_regexp)
     Definition.new(line_no, *m.captures) if m
  end

  def def_regexp
    /angular\.module\('(.*)'\)\.(factory|service|directive)\('(.*)'/
  end
end

class Definition
  attr_reader :line_no
  def initialize(line_no, mod, type, name)
    @line_no = line_no
    @module = mod
    @type = type
    @name = name
    @dependencies = []
  end

  def add_dependency(dependency)
    @dependencies << dependency
  end

  def annotation
    as_comments([ngdoc, name, "", description, "", requirements].flatten)
  end

  def annotate(lines)
    lines.insert(@line_no, annotation).join("\n")
  end

  private

  def as_comments(lines)
    "/**\n#{lines.map { |line| " " + "* #{line}".strip}.join("\n")}\n */"
  end

  def ngdoc
    "@ngdoc #{ngdoc_type}"
  end

  def ngdoc_type
    @type == "factory" ? "service" : @type
  end

  def name
    prefix = @type == 'directive' ? 'directives:' : ''
    "@name #{@module}.#{prefix}#{@name}"
  end

  def description
    %w{ @description TODO }
  end

  UTILS = %w{ commons logger generator }

  def requirements
    @dependencies.map { |dep| "@requires #{dependency_prefix(dep)}#{dep}" }
  end

  def dependency_prefix(dependency)
    if dependency.start_with?('$')
      ''
    elsif UTILS.include?(dependency)
      'arethusa.util.'
    else
      'arethusa.core.'
    end
  end
end

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
