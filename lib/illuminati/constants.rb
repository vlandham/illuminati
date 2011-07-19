module Illuminati
  CASAVA_PATH = "/home/solexa/CASAVA_1.8.0/bin"
  EMAIL_LIST = ["jfv@stowers.org"]
  QC_PATH = "/qcdata"
  SCRIPT_PATH = "/solexa/bin/scripts"
  ADMIN_PATH = "/solexa/runs"
  LOGS_PATH = "/solexa/runs/log"
  FLOWCELL_PATH_BASE = "/solexa"
  BASECALLS_PATH = File.join("Data", "Intensities", "BaseCalls") 
  FASTQ_COMBINE_PATH = "all"
  ELAND_COMBINE_PATH = "all"
  FASTQ_FILTER_PATH = "filter"
  PROJECT_PATTERN = "Project_*"
  FASTQ_STATS_PATTERN = "Basecall_Stats_*"
  ELAND_STATS_PATTERN = "Summary_Stats_*"
end
