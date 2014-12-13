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
    as_comments([ngdoc, name, "", description, "", requirements])
  end

  def annotate(lines)
    lines.insert(@line_no, annotation)
    %w{ function property }.each do |type|
      parse_child_annotation(lines, type)
    end
  end

  private

  def as_comments(lines, indent = "")
    [
      "#{indent}/**",
      lines.flatten.map { |line| "#{indent} "+ "* #{line}".strip },
      "#{indent} */"
    ].flatten.join("\n")
  end

  def parse_child_annotation(lines, type)
    i = 0
    while (i = find_marker(type, lines, i))
      lines[i] = create_child_annotation(lines, type, i)
    end
  end

  def create_child_annotation(lines, type, i)
    line = lines[i + 1]
    indent = line.match(/^(\s*)/)[1]
    definition_name = extract_assignment_name(line)
    lines[i] = as_comments([
      ngdoc(type),
      def_name(definition_name, type != 'function'),
      parent(type),
      '',
      description
    ], indent)
  end

  def find_marker(type, lines, start = 0)
    regexp = marker_regexp(type)
    lines.find_index { |line| line =~ regexp }
  end

  def marker_regexp(type)
    /^\s*\/\/.@arethusa-#{type}/
  end

  def extract_assignment_name(line)
    line.match(/(?:this|self)\.(.*?) =/)[1]
  end

  def ngdoc(type = ngdoc_type)
    "@ngdoc #{type}"
  end

  def ngdoc_type
    @type == "factory" ? "service" : @type
  end

  def link
    prefix = @type == 'directive' ? 'directives:' : ''
    "#{@module}.#{prefix}#{@name}"

  end

  def name
    "@name #{link}"
  end

  def def_name(fn, short = false)
    "@name #{short ? '' : "#{link}#"}#{fn}"
  end

  def parent(type)
    "@#{type}Of #{link}"
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
