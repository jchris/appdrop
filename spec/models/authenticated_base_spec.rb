require File.dirname(__FILE__) + '/../spec_helper'

describe "A User abstract class" do

  it "should have valid associations" do
    User.new.should have_valid_associations
  end

end

describe "An existing user" do
  before(:each) do
    @user = User.create!(:nickname => 'le quentin', :password => 'monkey', :password_confirmation => 'monkey', :email => 'test@foo.bar')
    @store.stub!(:buyers).and_return(User)
  end
  
  it "should authenticate with new or reset password" do
    @user.update_attributes(:password => 'new password', :password_confirmation => 'new password')
    User.authenticate('test@foo.bar', 'new password').should == @user
  end
  
  it "should not rehash password on login change" do
    @user.update_attributes(:email => 'test2@foo.bar')
    User.authenticate('test2@foo.bar', 'monkey').should == @user
  end
  
  it "should remember token" do
    @user.should_not be_remember_token
    lambda{ @user.remember_me }.should change( @user, :remember_token).from(nil)
    @user.remember_token_expires_at.should_not be_nil
    @user.should be_remember_token
  end
  
  it "should increment hit counter" do
    lambda{ @user.remember_me }.should change( @user, :visits_count).from(0).to(1)
  end
  
  it "should forget token" do
    lambda{ @user.remember_me }.should change( @user, :remember_token).from(nil)
    @user.should be_remember_token

    lambda{ @user.forget_me   }.should change( @user, :remember_token).to(nil)
    @user.should_not be_remember_token
  end

  it "should be remembered for a period" do
    before = 1.week.from_now.utc
    lambda{ @user.remember_me_for 1.week }.should change(@user, :remember_token).from(nil)
    after = 1.week.from_now.utc
    @user.remember_token_expires_at.should be_between(before,after)
  end
end

# http://rashkovskii.com/files/user_spec.rb
describe "A new user" do

  it "should create" do
    lambda{ user = create_user ; user.should_not be_new_record }.should change(User,:count).by(1)
  end
  
  it "should require email" do
    lambda{ u = create_user(:email => nil) ; u.should have_at_least(1).errors_on(:email) }.
          should_not change(User,:count)
  end
  
  it "should require password" do
    lambda{ u = create_user(:password => nil) ; u.should have_at_least(1).errors_on(:password) }.
          should_not change(User,:count)
  end

  it "should require password confirmation" do
    lambda{ u = create_user(:password_confirmation => nil) ; u.should have_at_least(1).errors_on(:password_confirmation) }.
          should_not change(User,:count)
  end

  def create_user(options = {})
    User.create({ :nickname => 're quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
  end
end
