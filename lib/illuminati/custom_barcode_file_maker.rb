
module Illuminati
  class CustomBarcodeFileMaker
    def self.make multiplex_data, flowcell_paths
      rtn = []
      (1..8).each do |lane|
        barcodes_for_lane = multiplex_data.select {|data| data[:lane].to_i == lane and data[:custom_barcode]}
        if !barcodes_for_lane.empty?
          write_barcodes barcodes_for_lane, flowcell_paths.custom_barcode_path(lane)
          rtn << lane
        end
      end
      rtn
    end

    def self.write_barcodes barcode_data, output_file
      File.open(output_file, 'w') do |file|
        barcode_data.each do |data|
          file << data[:custom_barcode] << "\t" << data[:custom_barcode] << "\n"
        end
      end
    end
  end # BarcodeFile
end
