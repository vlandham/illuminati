
fastqc_directory = ARGV[0]

module PFastqc
  class Combiner

    FIELDS = [{"name" => "basic", "index" => 0, "file" => nil},
             {"name" => "base qual", "index" => 1, "file" => "per_base_quality.png"},
             {"name" => "seq qual", "index" => 2, "file" => "per_sequence_quality.png"},
             {"name" => "seq content", "index" => 3, "file" => "per_base_sequence_content.png"},
             {"name" => "base GC", "index" => 4, "file" => "per_base_gc_content.png"},
             {"name" => "seq GC", "index" => 5, "file" => "per_sequence_gc_content.png"},
             {"name" => "base N", "index" => 6, "file" => "per_base_n_content.png"},
             {"name" => "len dist", "index" => 7, "file" => "sequence_length_distribution.png"},
             {"name" => "seq dup", "index" => 8, "file" => "duplication_levels.png"},
             {"name" => "over rep", "index" => 9, "file" => nil},
             {"name" => "kmers", "index" => 10, "file" => "kmer_profiles.png"}]

    STATUS = {"PASS" => "tick.png", "WARN" => "warning.png", "FAIL" => "error.png"}
    attr_accessor :fastqc_directory
    def initialize fastqc_directory
      self.fastqc_directory = fastqc_directory
    end

    def get_fastqc_directories
      Dir.glob(File.join(self.fastqc_directory, "*_fastqc"))
    end

    def create_name_row fields
      column_names = fields.map {|p| p["name"]}
      column_names.reduce("") {|o,v| o += "<td><font size=2>#{v}</font></td>"; o}
    end

    def write_summary_file output_directory, fastqc_dirs
      output_path = File.join(output_directory, "fastqc_summary.html")

      names_line = create_name_row FIELDS

      output = ""
      output += "<!DOCTYPE html>\n<html><head></head><body>"
      output += "<table cellpadding=1><tr><td></td><td><font size=2>&nbsp;&nbsp;&nbsp;sample&nbsp;&nbsp;&nbsp;</font></td>#{names_line}</tr>\n"

      fastqc_dirs.each do |fastq_dir|
        relative_fastq_dir = File.basename(fastq_dir)
        summary_filename = File.join(fastq_dir, "summary.txt")
        if !File.exists? summary_filename
          puts "ERROR: summary file does not exist for #{relative_fastq_dir}"
          next
        end

        baseurl = "#{relative_fastq_dir}/fastqc_report.html"

        summaries = File.open(summary_filename, 'r').read.split("\n").collect{|l| l.split("\t")[0]}
        summary_lines = []
        summaries.each_with_index do |summary, summary_index|
          summary_icon = File.join(relative_fastq_dir, "Icons", STATUS[summary])
          url = "#{baseurl}#M#{summary_index}"
          summary_lines << "<td><a href=\"#{url}\"><img border=0 src=\"#{summary_icon}\"></a></td>"
        end

        file_name = relative_fastq_dir.gsub("_fastqc","")

        output += "<tr><td><font size=2><a href=\"#{baseurl}\">#{file_name}</a></font></td><td><font size=2>#{""}</font></td>#{summary_lines.join(" ")}</tr>\n"
      end

      output += "</table>"
      output += "<br/>"
      output += "<font size=2><a href=\"http://wiki/research/FastQC/SIMRreports\">How to interpret FastQC results</a></font>"
      output += "\n</body></html>"
      write_file(output_path, output)
      output_path
    end

    def write_plots_file output_directory, fastqc_dirs
      output_path = File.join(output_directory, "fastqc_plots.html")

      plots = FIELDS.select {|f| f["file"] != nil}
      names_line = create_name_row plots

      output = ""
      output += "<!DOCTYPE html>\n<html><head></head><body>"
      output += "<table cellpadding=1><tr><td></td><td><font size=2>&nbsp;&nbsp;&nbsp;sample&nbsp;&nbsp;&nbsp;</font></td>#{names_line}</tr>\n"

      fastqc_dirs.each do |fastq_dir|
        relative_fastq_dir = File.basename(fastq_dir)

        image_lines = plots.map do |plot|
          plot_thumbnail = File.join(relative_fastq_dir, "thumbs", plot["file"])

          if !File.exists?(File.join(File.dirname(fastq_dir), plot_thumbnail))
            puts "ERROR: thumbail not present: #{plot_thumbnail}"
          end
          "<td><a href=\"#{relative_fastq_dir}/fastqc_report.html#M#{plot["index"]}\"><img border=0 src=\"#{plot_thumbnail}\"></a></td>"
        end

        image_row = image_lines.join(" ")

        file_name = relative_fastq_dir.gsub("_fastqc","")

        output += "<td><a href=\"#{relative_fastq_dir}/fastqc_report.html\">#{file_name}</a></font></td><td nowrap>&nbsp;&nbsp;<font size=2>#{""}</font>&nbsp;&nbsp;</td></td>#{image_row}</tr>\n"
      end

      output += "</table>"
      output += "<br/>"
      output += "<font size=2><a href=\"http://wiki/research/FastQC/SIMRreports\">How to interpret FastQC results</a></font>"
      output += "\n</body></html>"
      write_file(output_path, output)
      output_path
    end

    def combine
      thumber = ThumbMaker.new(self.fastqc_directory)
      thumber.thumb
      fastqc_dirs = get_fastqc_directories
      fastqc_dirs = fastqc_dirs.sort {|a,b| a.split("_")[1] <=> b.split("_")[1]}

      write_plots_file(fastqc_directory, fastqc_dirs)
      write_summary_file(fastqc_directory, fastqc_dirs)

      Dir.chdir self.fastqc_directory do
        system("rm -f *.zip")
      end

    end

    def write_file output_filename, content
      File.open(output_filename, 'w') {|file| file.puts content }
    end
  end

  class ThumbMaker
    attr_accessor :fastqc_directory
    def initialize fastqc_directory
      self.fastqc_directory = fastqc_directory
    end

    def get_fastqc_directories
      Dir.glob(File.join(self.fastqc_directory, "*_fastqc"))
    end

    def thumb
      output_dir = "thumbs"
      directories = get_fastqc_directories
      directories.each do |fastqc_dir|
        puts "creating thumbs for #{fastqc_dir}"
        Dir.chdir fastqc_dir do
          system("mkdir -p #{output_dir}")
          images = Dir.glob(File.join("Images", "*.png"))
          images.each do |img|
            output_filename = File.join(output_dir, File.basename(img))
            command = "convert -contrast -thumbnail 110 \"#{img}\" #{output_filename}"
            system(command)
          end
        end
      end
    end
  end
end

combiner = PFastqc::Combiner.new(fastqc_directory)

combiner.combine
