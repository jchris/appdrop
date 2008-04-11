require File.dirname(__FILE__) + '/../spec_helper'

describe App do
  before(:each) do
    @app = App.new :port => 3100, :key => 'myapp', :user_id => 3
  end

  it "should be valid" do
    @app.should be_valid
  end
end

describe App, "initializing configuration" do
  before(:each) do
    raise "OMFG don't run me on the production server!" if (/nginx/.match `ls /etc/nginx`)
    `rm /etc/nginx/sites-enabled/*`
    `rm -rf /var/apps/*`
    @app = App.new :port => 3100, :key => 'myapp', :user_id => 3
  end
  it "should create the config file" do
    @app.initialize_configuration
    x = `cat /etc/nginx/sites-enabled/myapp`
    x.should match(/3100/)
  end
  it "should create the app directories" do
    @app.initialize_configuration
    ls = `ls /var/apps/myapp`
    ls.should match(/log/)
    ls.should match(/data/)
    ls.should match(/app/)
  end
  it "should set a portfile" do
    @app.initialize_configuration
    lines = IO.readlines("/var/apps/myapp/portfile")
    lines[0].should == '3100'
  end
end