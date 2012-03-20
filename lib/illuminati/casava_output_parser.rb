require 'illuminati/html_parser'
require 'illuminati/flowcell_record'

module Illuminati
  class CasavaOutputParser
    DATA_CONVERSIONS = {"Yield (Mbases)" => :int, "# Reads" => :int,
                        "Sample Yield (Mbases)" => :int, "Clusters (raw)" => :int,
                        "Clusters (PF)" => :int, "1st Cycle Int (PF)" => :int}

    DOUBLED_FIELDS = ["Yield (Mbases)", "# Reads", "Clusters (raw)", "Clusters (PF)"]

    DEMULTIPLEX_FIELD_CONVERSIONS = {"Sample Ref" => "Species",
                                     "Yield (Mbases)" => "Sample Yield (Mbases)",
                                     "% PF" => "% PF Clusters",
                                     "% of &gt;= Q30 Bases (PF)" => "% &gt;=Q30 bases (PF)",
                                     "Mean Quality Score (PF)" => "Mean Quality SCore (PF)",
                                     "# Reads" => "Clusters (raw)"
    }

    attr_reader :demultiplex_stats_filename, :sample_summary_filenames

    def initialize demultiplex_stats_filename, sample_summary_filenames
      @demultiplex_filename = demultiplex_stats_filename || ""

      sample_summary_filenames = [sample_summary_filenames].flatten
      @sample_summary_filenames = sample_summary_filenames
    end

    def data_for sample, read
      data = {}

      sample_summary_data = sample_summary_data_for_sample sample, read
      data.merge!(sample_summary_data) if sample_summary_data

      demultiplex_data = demultiplex_data_for_sample sample
      data.merge!(demultiplex_data) if demultiplex_data

      process_data(data)

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

    def process_data data
      # add pass filter clusters
      if data["% PF Clusters"] and data["Clusters (raw)"] and (!data["Clusters (PF)"] or data["Clusters (PF)"] == 0)
        data["Clusters (PF)"] = data["Clusters (raw)"].to_f * (data["% PF Clusters"].to_f / 100.0)
        data["Clusters (PF)"] = data["Clusters (PF)"].round.to_i
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
      @sample_summary_filenames.each do |sample_summary_filename|
        if File.exists?(sample_summary_filename)
          html_parser = HtmlParser.new
          sample_summary_data = html_parser.table_data(sample_summary_filename)
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
            convert_data(sample_data)
            return sample_data
          end
        end
      end
      nil
    end

    def demultiplex_matches_sample? demultiplex_sample, sample
      # this is the normal match that should hit when using truseq, custom, or
      # no barcoding.
      if demultiplex_sample["Lane"] == sample.lane.to_s
        if demultiplex_sample["Index"] == sample.illumina_barcode_string
          return true
        end

        # this is a hack to satisfy when a lane has a single sample that is
        # barcoded in LIMS - but is run as not barcoded.
        if demultiplex_sample["Index"] == "NoIndex" and sample.illumina_barcode_string != "Undetermined"
          return true
        end
      end
      return false
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
          if demultiplex_matches_sample? demultiplex_sample, sample
            # puts demultiplex_sample.inspect
            # puts "match #{sample.illumina_barcode_string}"

            demult_data = demultiplex_sample
            DEMULTIPLEX_FIELD_CONVERSIONS.each do |d_key, ss_key|
              demult_data[ss_key] = demult_data[d_key]
            end

            convert_data(demult_data)

            if sample.read_count == 2
              DOUBLED_FIELDS.each do |d_key|
                if demult_data[d_key]
                  puts "dividing #{demult_data[d_key]}"
                  demult_data[d_key] = demult_data[d_key] / 2
                end
              end
            end

            puts demult_data.inspect

            return demult_data
          end
        end
      end
      nil
    end
  end
end
