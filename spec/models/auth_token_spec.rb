require File.dirname(__FILE__) + '/../spec_helper'

describe AuthToken do
  before(:each) do
    @auth_token = AuthToken.new :user_id => 1, :app_id => 1
  end

  it "should be valid" do
    @auth_token.save.should be_true
  end
end
