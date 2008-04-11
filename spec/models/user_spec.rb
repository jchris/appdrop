require File.dirname(__FILE__) + '/../spec_helper'

describe "A User" do

  before(:each) do
   @user = User.new :nickname => 'le quentin', :password => 'blah', :password_confirmation => 'blah', :email => 'quentin@example.com'
  end

  it "should have valid associations" do
     @user.save!
     @user.should have_valid_associations
  end

  it "should protect against updates to secure attributes" do
    @user.save
    ca = @user.created_at
    @user.update_attributes(:created_at => 3)
    @user.created_at.should == ca
  end
  
end

