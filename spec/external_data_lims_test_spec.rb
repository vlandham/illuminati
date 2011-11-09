require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/external_data_lims_test'


describe Illuminati::ExternalDataLimsTest do
  before(:each) do
    @lims = Illuminati::ExternalDataLimsTest.new
  end
end
