
module Illuminati
  #
  # Uses multiplex data to create individual files for all lanes that use custom barcodes.
  #
  class CustomBarcodeFileMaker
    #
    # Creates custom barcode files given multiplex data and a FlowcellPaths instance. These files
    # are created because we want to examine SampleMultiplex.csv only once at the beginning of the
    # primary analysis process. So we create these barcode files at the start, but only use them during
    # the post run process. This work around could probably be removed with a bit better program design.
    #
    # == Parameters
    # flowcell::
    #   Instance of FlowcellRecord
    #
    # == Returns
    # After this method is called, a single file for each lane that uses custom barcodes is created.
    # The location of these files is based on the flowcell_paths. If no lanes used custom barcoding,
    # (ultimately determined by the custom barcode column in SampleMultiplex.csv) then no files will
    # be created. Existing files will be over-written.
    #
    def self.make flowcell
      rtn = []
      custom_lanes = Hash.new {|h,k| h[k] = []}
      flowcell.each_sample_with_lane do |sample, lane|
        if sample.barcode_type == :custom
          custom_lanes[sample.lane.to_i] << sample.barcode
        end
      end

      custom_lanes.each do |lane, barcodes|
        write_barcodes barcodes, flowcell.paths.custom_barcode_path(lane)
        rtn << lane
      end
      rtn
    end

    #
    # Performs the acutal write to each file with custom barcode info.
    #
    # == Parameters:
    # barcodes::
    #   Array of custom barcodes for a lane
    #
    # output_file::
    #   Filename for one custom barcode lane file.
    #
    def self.write_barcodes barcodes, output_file
      File.open(output_file, 'w') do |file|
        barcodes.each do |barcode|
          file << barcode << "\t" << barcode << "\n"
        end
      end
    end
  end # BarcodeFile
end
