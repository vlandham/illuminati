require 'illuminati/html_parser'
require 'illuminati/flowcell_record'

module Illuminati
  class CasavaOutputParser
    DATA_CONVERSIONS = {"Yield (Mbases)" => :int, "# Reads" => :int,
                        "Sample Yield (Mbases)" => :int, "Clusters (raw)" => :int,
                        "Clusters (PF)" => :int, "1st Cycle Int (PF)" => :int}

    DEMULTIPLEX_FIELD_CONVERSIONS = {"Sample Ref" => "Species",
                                     "Yield (Mbases)" => "Sample Yield (Mbases)",
                                     "% PF" => "% PF Clusters",
                                     "% of &gt;= Q30 Bases (PF)" => "% &gt;=Q30 bases (PF)",
                                     "Mean Quality Score (PF)" => "Mean Quality SCore (PF)",
                                     "# Reads" => "Clusters (raw)"
    }

    attr_reader :demultiplex_stats_filename, :sample_summary_filename
    def initialize demultiplex_stats_filename, sample_summary_filename
      @demultiplex_filename = demultiplex_stats_filename || ""
      @sample_summary_filename = sample_summary_filename || ""
    end

    def data_for sample, read
      data = {}

      demultiplex_data = demultiplex_data_for_sample sample
      data.merge!(demultiplex_data) if demultiplex_data

      sample_summary_data = sample_summary_data_for_sample sample, read
      data.merge!(sample_summary_data) if sample_summary_data



      convert_data(data)

      data
    end

    def convert_data data
      DATA_CONVERSIONS.each do |key, type|
        if data[key]
          data[key] = case(type)
                      when :int
                        remove_commas(data[key]).to_i
                      when :float
                        remove_commas(data[key]).to_f
                      else
                        data[key]
                      end
        end
      end
    end

    #
    #
    #
    def remove_commas(value)
      value.gsub(",","") if value
    end

    #
    #
    def sample_summary_data_for_sample sample, read
      if File.exists?(@sample_summary_filename)
        html_parser = HtmlParser.new
        sample_summary_data = html_parser.table_data(@sample_summary_filename)
        # we need both the barcode-lane summary data and
        # the sample results summary for the appropriate read.
        sample_data = {}
        # barcode lane data is in table[0]
        sample_summary_data[0].each do |barcode_lane_data|
          if barcode_lane_data["Lane"] == sample.lane.to_s and
          barcode_lane_data["Barcode"] == sample.illumina_barcode_string
            sample_data.merge! barcode_lane_data
            break
          end
        end

        read_index = read.to_i == 1 ? 1 : 2
        sample_summary_data[read_index].each do |sample_results_data|
          if sample_results_data["Sample"] == sample_data["Sample"]
            sample_data.merge! sample_results_data
            break
          end
        end

        unless sample_data.empty?
          return sample_data
        end
      end
      nil
    end

    #
    # Returns data from Demultiplex_Stats.htm for a particular sample.
    # Sample matching is done using the Sample ID.
    #
    def demultiplex_data_for_sample sample
      if File.exists?(@demultiplex_filename)
        html_parser = HtmlParser.new
        demultiplex_data = html_parser.table_data(@demultiplex_filename)[0]
        demultiplex_data.each do |demultiplex_sample|
          if demultiplex_sample["Lane"] == sample.lane.to_s and
            demultiplex_sample["Index"] == sample.illumina_barcode_string

            demult_data = demultiplex_sample
            DEMULTIPLEX_FIELD_CONVERSIONS.each do |d_key, ss_key|
              demult_data[ss_key] = demult_data[d_key]
            end

            return demult_data
          end
        end
      end
      nil
    end
  end
end
