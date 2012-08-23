
require 'json'

ASSESTS_PATH = File.join(File.dirname(__FILE__), "..", "..", "assests")

module SimpleDistribute
  class Distributer

    attr_accessor :db_directory

    def initialize db_directory
      self.db_directory = db_directory
    end

    def create_db_directory
      command = "mkdir -p #{db_directory}"
      execute command
    end

    def get_name task_script
      File.basename(task_script, File.extname(task_script))
    end

    def write_database task_name, database
      db_filename = File.expand_path(File.join(self.db_directory, "#{task_name}.json"))

      File.open(db_filename, 'w') do |file|
        file.puts database.to_json
      end
      db_filename
    end

    def submit task_script, options
      task_name = get_name(task_script)
      if !File.exists?(task_script)
        puts "# ERROR: no process script found: #{task_script}"
        return nil
      end

      wrapper_script = get_wrapper_script
      return nil unless wrapper_script
      create_db_directory

      db_filename = ""
      if options[:database]
        db_filename = write_database task_name, database
      end

      full_task_name = task_name

      if options[:prefix]
        full_task_name = "#{options[:prefix]}_#{task_name}"
      end

      Dir.chdir(self.db_directory) do
        # run for all jobs in database
        command = "qsub -cwd -V"
        if options[:dependency]
          command += " -hold_jid #{options[:dependency]}"
        end

        if options[:database]
          if options[:database].size > 0
            command += " -t 1-#{options[:database].size}"
          else
            puts "ERROR: database provided, but size is 0"
          end
        end

        command += " -N #{full_task_name} #{wrapper_script} #{task_script}"
        args = options[:args] || ""
        args = db_filename + " " + args unless db_filename.empty?

        command += " #{args}"

        execute(command)
      end
      full_task_name
    end

    def submit_parallel task_script, task_prefix, database, dependency = nil
      self.submit(task_script, {:database => database, :prefix => task_prefix, :dependency => dependency})
    end

    def submit_one task_prefix, task_name, dependency = nil, *args
      submit(task_name, {:prefix => task_prefix, :dependency => dependency, :args => args.join(" ")})
    end

    def get_wrapper_script
      wrapper_script_filename = File.join(ASSESTS_PATH, "wrapper.sh")
      if !File.exists?(wrapper_script_filename)
        puts "# ERROR: no wrapper script found: #{wrapper_script_filename}"
        wrapper_script_filename = nil
      end
      wrapper_script_filename
    end

    def execute command
      puts command
      system(command)
    end

  end
end
