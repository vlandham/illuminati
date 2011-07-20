module Illuminati
  class TabFileParser
    def parse filename, has_header = true
      file_string = File.open(filename, 'r').read
      data = parse_tabbed_string(file_string, has_header)
    end

    def parse_tabbed_string string, has_header = true
      data = []
      lines = string.split("\n")
      elements = lines.collect {|line| line.split("\t")}
      headers = []
      if has_header
        headers = elements.shift
      else
        headers = (1..elements[0].size).to_a
      end

      elements.each do |elements_row|
        row_data = {}
        elements_row.each_with_index do |element, index|
          row_data[headers[index]] = element
        end
        data << row_data
      end
      data
    end
  end
end
