
$:.unshift(File.join(File.dirname(__FILE__), "..", "simple_distribute"))

require 'simple_distribute'

WORKER_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), "worker.rb"))
COMBINER_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), "combine.rb"))
EMAIL_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), "..", "assests", "email.rb"))

module PFastqc
  class Start
    attr_accessor :fastqc_path
    def initialize fastqc_path
      self.fastqc_path = fastqc_path
      if !File.exists? self.fastqc_path
        raise "ERROR - fastqc path not found: #{fastqc_path}"
      end

      if !File.exists? WORKER_SCRIPT
        raise "ERROR - no worker script found: #{WORKER_SCRIPT}"
      end
      if !File.exists? COMBINER_SCRIPT
        raise "ERROR - no combiner script found: #{COMBINER_SCRIPT}"
      end
      if !File.exists? EMAIL_SCRIPT
        raise "ERROR - no email script found: #{EMAIL_SCRIPT}"
      end
    end

    # create an array of all the fastq files in the directory
    # Use simple_distribute to send out a bunch of worker scripts
    # add combiner as a dependent of the run, so it will run at
    # the end of all the workers
    def run fastq_directory, output_directory = File.join(fastq_directory, "fastqc"), fastq_pattern = "*.fastq.gz"

      fastq_files = Dir.glob(File.expand_path(File.join(fastq_directory, fastq_pattern)))
      output_directory = File.expand_path(output_directory)
      puts "Analyzing #{fastq_files.size} files with Fastqc"
      return unless fastq_files.size > 0

      system("mkdir -p #{output_directory}")
      database = []
      fastq_files.each do |fastq_file|
        database << {"input" => fastq_file, "output" => output_directory, "program" => fastqc_path}
      end

      db_directory = File.join(output_directory, "fastqc_db")
      system("mkdir -p #{db_directory}")

      distributer = SimpleDistribute::Distributer.new(db_directory)

      worker_task_name = Distributer.submit(WORKER_SCRIPT, {:prefix => "fastqc", :database => database})

      combiner_task_name = Distributer.submit(COMBINER_SCRIPT, {:prefix => "fastqc", :dependency => worker_task_name}, :args => output_directory)

      email_task_name = Distributer.submit(EMAIL_SCRIPT, {:prefix => "fastqc", :dependency => combiner_task_name, :args => "FASTQC A_FLOWCELL"
    end
  end
end
