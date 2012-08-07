
module Illuminati
  class SampleSheetParser
    # returns data as a hash of values
    def self.data_for sample_sheet_filename
      data = {}

      if !File.exists?(sample_sheet_filename)
        puts "ERROR: no SampleSheet.csv file found at #{sample_sheet_filename}"
        raise "no_sample_sheet_file"
      end

      sample_sheet = File.open(sample_sheet_filename, 'r').readlines()

      if sample_sheet.empty?
        puts "ERROR: no sample sheet data in #{sample_sheet_filename}"
        raise "no_sample_sheet_data"
      end
      data["header"] = get_header sample_sheet
      data["samples"] = get_samples sample_sheet

      data
    end

    def self.get_header sample_sheet
      header_section = get_section("Header", sample_sheet)
      data = {}
      header_section.each do |line|
        key_value = line.chomp.split(",")
        data[key_value[0]] = key_value[1]
      end
      data
    end

    def self.get_samples sample_sheet
      data_section = get_section("Data", sample_sheet)
      data = []
      titles = data_section.shift().chomp().split(",")
      data_section.each_with_index do |line, index|
        sample_data = Hash[titles.zip(line.chomp().split(","))]
        sample_data["Sample_Number"] = "#{index + 1}"
        data << sample_data
      end
      data
    end

    def self.get_section section_name, sample_sheet_data
      section_data = []
      found = false
      sample_sheet_data.each do |line|
        if found
          if line.chomp.empty?
            break
          end
          section_data << line
        end

        if line.chomp =~ /\[#{section_name}\]/
          found = true
        end
      end
      section_data
    end
  end
end
