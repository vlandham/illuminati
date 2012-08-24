
fastqc_directory = ARGV[0]

module PFastqc
  class Combiner

    PLOTS = [{"name" => "base qual", "index" => 1, "file" => "per_base_quality.png"},
             {"name" => "seq qual", "index" => 2, "file" => "per_sequence_quality.png"},
             {"name" => "seq content", "index" => 3, "file" => "per_base_sequence_content.png"},
             {"name" => "base GC", "index" => 4, "file" => "per_base_gc_content.png"},
             {"name" => "seq GC", "index" => 5, "file" => "per_sequence_gc_content.png"},
             {"name" => "base N", "index" => 6, "file" => "per_base_n_content.png"},
             {"name" => "len dist", "index" => 7, "file" => "sequence_length_distribution.png"},
             {"name" => "seq dup", "index" => 8, "file" => "duplication_levels.png"},
             {"name" => "kmers", "index" => 10, "file" => "kmer_profiles.png"}]

    attr_accessor :fastqc_directory
    def initialize fastqc_directory
      self.fastqc_directory = fastqc_directory
    end

    def get_fastqc_directories
      Dir.glob(File.join(self.fastqc_directory, "*_fastqc"))
    end

    def write_plots_file output_directory, fastqc_dirs
      fastqc_dirs = fastqc_dirs.sort {|a,b| a.split("_")[1] <=> b.split("_")[1]}
      output_path = File.join(output_directory, "fastqc_plots_new.html")

      column_names = PLOTS.map {|p| p["name"]}
      names_line = column_names.reduce("") {|o,v| o += "<td><font size=2>#{v}</font></td>"; o}

      output = "<table cellpadding=1><tr><td></td><td><font size=2>&nbsp;&nbsp;&nbsp;sample&nbsp;&nbsp;&nbsp;</font></td>#{names_line}</tr>\n"

      fastqc_dirs.each do |fastq_dir|
        relative_fastq_dir = File.basename(fastq_dir)

        image_lines = PLOTS.map do |plot|
          plot_thumbnail = File.join(relative_fastq_dir, "thumbs", plot["file"])
          if !File.exists?(plot_thumbnail)
            puts "ERROR: thumbail not present: #{plot_thumbnail}"
            plot_thumbnail = "N/A"
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
      File.open(output_path, 'w') {|file| file.puts output }
      output_path
    end

    def combine
      thumber = ThumbMaker.new(self.fastqc_directory)
      # thumber.thumb
      fastqc_dirs = get_fastqc_directories

      write_plots_file(fastqc_directory, fastqc_dirs)

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
