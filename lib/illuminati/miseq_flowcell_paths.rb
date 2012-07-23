module Illuminati
  class MiseqFlowcellPaths < FlowcellPaths
    def initialize flowcell_id, testing = false, paths = Paths
      super(flowcell_id, testing, paths)
    end

    def unaligned_dir
      File.join(base_dir, BASECALLS_PATH)
    end

    def unaligned_project_dir
      File.join(base_dir, BASECALLS_PATH)
    end
  end
end
