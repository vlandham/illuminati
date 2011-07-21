
module Illuminati
  #
  # Uses multiplex data to create individual files for all lanes that use custom barcodes.
  #
  class CustomBarcodeFileMaker
    #
    # Creates custom barcode files given multiplex data and a FlowcellData instance. These files
    # are created because we want to examine SampleMultiplex.csv only once at the beginning of the
    # primary analysis process. So we create these barcode files at the start, but only use them during
    # the post run process. This work around could probably be removed with a bit better program design.
    #
    # == Parameters
    # multiplex_data::
    #   multiplex_data originally parsed from SampleMultiplex.csv file. See SampleMultiplex for details.
    #
    # flowcell_data::
    #   FlowcellData instance to acquire the custom barcode path names for each lane.
    #   Method calls custom_barcode_path method
    #
    # == Returns
    # After this method is called, a single file for each lane that uses custom barcodes is created.
    # The location of these files is based on the flowcell_data. If no lanes used custom barcoding,
    # (ultimately determined by the custom barcode column in SampleMultiplex.csv) then no files will
    # be created. Existing files will be over-written.
    #
    def self.make multiplex_data, flowcell_data
      rtn = []
      (1..8).each do |lane|
        barcodes_for_lane = multiplex_data.select {|data| data[:lane].to_i == lane and data[:custom_barcode]}
        if !barcodes_for_lane.empty?
          write_barcodes barcodes_for_lane, flowcell_data.custom_barcode_path(lane)
          rtn << lane
        end
      end
      rtn
    end

    #
    # Performs the acutal write to each file with custom barcode info.
    #
    # == Parameters:
    # barcode_data::
    #   One line of custom barcode data.
    #
    # output_file::
    #   Filename for one custom barcode lane file.
    #
    def self.write_barcodes barcode_data, output_file
      File.open(output_file, 'w') do |file|
        barcode_data.each do |data|
          file << data[:custom_barcode] << "\t" << data[:custom_barcode] << "\n"
        end
      end
    end
  end # BarcodeFile
end
