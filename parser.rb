class Parser
  def initialize(file)
    @file = file
    @lines = File.read(file).split("\n");
  end

  def annotate
    @lines.each_with_index do |line, i|
      next unless @definition = get_definition(line, i)
      break;
    end

    return unless @definition

    i = @definition.line_no

    unless @lines[i].end_with?('{')
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

