module Illuminati
  #
  # Converts Tab delineated files into Array of hashes
  #
  class TabFileParser
    #
    # Reads in the contents of a file and converts it to
    # an Array of hashes. There will be one hash in the array
    # for each line in the tab-separated file, minus
    # the header if has_header is set to true.
    # Missing values in columns will be nil.
    #
    # == Parameters:
    # filename::
    #   Path to tab-separated file to convert
    # has_header::
    #   if true, the Hashes will be keyed off of the
    #   appropriate column headers. If false, the Hashes
    #   will be keyed off of indexes starting at 0
    #
    # == Returns:
    # Array of Hashes. If has_header, hash keys will be the
    # string associated with the column the value is in.
    # There will be one element in the hash for each column
    # in the tab-separated file
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
