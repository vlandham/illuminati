require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/config'

describe Illuminati::Config do
  describe "defaults" do
    before(:each) do
      @config = Illuminati::Config.parse_config
    end
    it "should load defaults with no config present" do
      @config['qc_path'].should == '/qcdata'
      @config['fastq_filter_path'].should == 'filter'
      @config['casava_path'].should == '/home/solexa/CASAVA_1.8.1/bin'
    end
  end

  describe "env" do
    before(:each) do
      @config_file = File.expand_path(File.join(File.dirname(__FILE__), "data", "test.config.yaml"))
      File.exists?(@config_file).should == true
      ENV['ILLUMINATI_CONFIG'] = @config_file
      @config = Illuminati::Config.parse_config
    end

    it "should load from config file" do
      @config['fastq_filter_path'].should == 'test_filter'
      @config['email_list'].include?('test@test.org').should == true
      @config['email_server'].should == 'testserver:25'
    end
  end
end
