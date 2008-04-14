require File.dirname(__FILE__) + '/../spec_helper'
require 'lib/appdrop_upload'

GAPP_FIXTURE = "#{RAILS_ROOT}/spec/fixtures/guestbook"
INVALID_FIXTURE = "#{RAILS_ROOT}/spec/fixtures/invalid"
MISSING_FIXTURE = "#{RAILS_ROOT}/spec/fixtures/thisisnothere"

describe AppdropUpload, "upload where there is no token in ~/.appdrop" do
  before(:each) do
    `rm ~/.appdrop`
    Kernel.stub!(:puts)
    Kernel.stub!(:gets).and_return("authtoken\n")
  end
  it "should tell the user to go to http://appdrop.com/apps/guestbook/manage to get the token" do
    Kernel.should_receive(:puts).with(/appdrop\.com\/apps\/guestbook\/manage/)
    AppdropUpload.process [GAPP_FIXTURE]
  end
  it "should prompt for the token" do
    Kernel.should_receive(:gets).and_return("authtoken\n")
    AppdropUpload.process [GAPP_FIXTURE]
  end
  it "should save the token to ~/.appdrop" do
    AppdropUpload.process [GAPP_FIXTURE]
    filebody = `cat ~/.appdrop`
    filebody.should == "authtoken"
  end
  it "should go on to upload"
end

describe AppdropUpload, "upload where there is a token in ~/.appdrop with a valid app directory" do
  before(:each) do
    `echo 'testtoken' > ~/.appdrop`
  end
  it "should tar up the directory given on ARGV" do
    AppdropUpload.process [GAPP_FIXTURE]
    ls = `ls /tmp`
    ls.should match(/appdrop/)
  end
end

describe AppdropUpload, "upload where there is a token in ~/.appdrop with an error tarring" do
  before(:each) do
    `echo 'testtoken' > ~/.appdrop`
    Kernel.stub!(:system).and_return(false)
  end
  it "should raise a file error" do
    lambda{AppdropUpload.process [GAPP_FIXTURE]}.should raise_error(AppdropUpload::FileError)
  end
end

describe AppdropUpload, "upload where there is a token in ~/.appdrop with an invalid app directory" do
  before(:each) do
    `echo 'testtoken' > ~/.appdrop`
  end
  it "should raise an error" do
    lambda{AppdropUpload.process [INVALID_FIXTURE]}.should raise_error(AppdropUpload::FileError)
  end
end