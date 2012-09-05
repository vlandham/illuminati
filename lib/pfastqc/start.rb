
$:.unshift(File.join(File.dirname(__FILE__), "..", "simple_distribute"))

require 'simple_distribute'

WORKER_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), "worker.rb"))
COMBINER_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), "combine.rb"))
DISTRIBUTE_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "assests", "cp_files.rb"))
EMAIL_SCRIPT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "assests", "email.rb"))

module PFastqc
  class Start
    attr_accessor :fastqc_path, :data
    def initialize fastqc_path, data = {}
      self.fastqc_path = fastqc_path
      self.data = data
      if !File.exists? self.fastqc_path
        raise "ERROR - fastqc path not found: #{fastqc_path}"
      end

      if !File.exists? WORKER_SCRIPT
        raise "ERROR - no worker script found: #{WORKER_SCRIPT}"
      end
      if !File.exists? COMBINER_SCRIPT
        raise "ERROR - no combiner script found: #{COMBINER_SCRIPT}"
      end
      if !File.exists? DISTRIBUTE_SCRIPT
        raise "ERROR - no distribute script found: #{DISTRIBUTE_SCRIPT}"
      end
      if !File.exists? EMAIL_SCRIPT
        raise "ERROR - no email script found: #{EMAIL_SCRIPT}"
      end
    end

    # create an array of all the fastq files in the directory
    # Use simple_distribute to send out a bunch of worker scripts
    # add combiner as a dependent of the run, so it will run at
    # the end of all the workers
    def run fastq_directory, dependency = nil, output_directory = File.join(fastq_directory, "fastqc"), fastq_pattern = "*.fastq.gz"

      system("mkdir -p #{output_directory}")

      fastq_files = Dir.glob(File.expand_path(File.join(fastq_directory, fastq_pattern)))
      output_directory = File.expand_path(output_directory)
      puts "Analyzing #{fastq_files.size} files with Fastqc"
      return unless fastq_files.size > 0

      database = []
      fastq_files.each do |fastq_file|
        database << {"input" => fastq_file, "output" => output_directory, "program" => fastqc_path}
      end

      db_directory = File.join(output_directory, "fastqc_db")
      system("mkdir -p #{db_directory}")

      distributer = SimpleDistribute::Distributer.new(db_directory)

      worker_task_name = distributer.submit(WORKER_SCRIPT, {:prefix => "fastqc", :database => database, :dependency => dependency})

      combiner_task_name = distributer.submit(COMBINER_SCRIPT, {:prefix => "fastqc", :dependency => worker_task_name, :args => output_directory})

      wait_on_task = combiner_task_name

      if self.data["projects"]
        puts "Projects found!! - distributing to #{self.data["projects"].size} locations"
        distribute_database = []
        self.data["projects"].each do |out|
          distribute_database << {"input" => output_directory, "output" => out, "recursive" => true}
        end

        distribute_task_name = distributer.submit(DISTRIBUTE_SCRIPT, {:prefix => "fastqc", :dependency => combiner_task_name, :database => distribute_database})
        wait_on_task = distribute_task_name
      else
        puts "NO projects found!! - NOT DISTRIBUTING DATA"
      end

      flowcell_id = "A_FLOWCELL"
      if self.data["flowcell_id"]
        flowcell_id = self.data["flowcell_id"].strip
      end

      email_task_name = distributer.submit(EMAIL_SCRIPT, {:prefix => "fastqc", :dependency => wait_on_task, :args => "FASTQC #{flowcell_id}"})
      email_task_name
    end
  end
end
