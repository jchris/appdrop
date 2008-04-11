require File.dirname(__FILE__) + '/../spec_helper'

describe LoginController, "GET /login" do

  def do_get
    get :login    
  end

  it "should render the login form" do
    do_get
    response.should render_template(:login)
  end

  describe "with valid app params" do
    before(:each) do
      @app = mock_model(App)
      App.stub!(:find_by_key).and_return(@app)
    end
    def do_get
      get :login, :continue => "http://fug-this.appspot.com/_ah/login%3Fcontinue%3Dhttp://fug-this.appspot.com/"
    end
    it "should find the app" do
      App.should_receive(:find_by_key).with('fug-this').and_return(@app)
      do_get
    end
    it "should render the login form" do
      do_get
      response.should render_template(:login)
    end
  end

  describe "with invalid app params" do
    before(:each) do
      App.stub!(:find_by_key).and_return(nil)
    end
    def do_get
      get :login, :continue => "http://not-fug-this.appspot.com/_ah/login%3Fcontinue%3Dhttp://not-fug-this.appspot.com/"
    end
    it "should not find the app" do
      App.should_receive(:find_by_key).with('not-fug-this').and_return(nil)
      do_get
    end
    it "should render invalid template" do
      do_get
      response.should render_template(:invalid)
    end
  end

  describe "with an current session" do
    before(:each) do
      @user = mock_model(User)
      controller.stub!(:current_user).and_return @user
    end
    it "should render the authorize page" do
      do_get
      response.should render_template(:authorize)
    end
  end
end

describe LoginController, "POST /authorize while logged in with app info" do
  it "should redirect to the app continue page"
end

describe LoginController, "POST /authorize while logged in with bad app info" do
  it "should barf"
end

describe LoginController, "POST /authorize while logged in without app info" do
  it "should barf"
end

describe LoginController, "POST /authorize while logged out" do
  it "should barf"
end

describe LoginController, "POST /login without remember me and with app params" do

  before(:each) do
    @user = mock_user
    User.stub!(:authenticate).and_return(@user)
    controller.stub!(:logged_in?).and_return(true)
    @app = mock_model(App)
    App.stub!(:find_by_key).and_return(@app)
  end

  it 'should authenticate user' do
    User.should_receive(:authenticate).with('user', 'password').and_return(@user)
    post :create, :email => 'user', :password => 'password'
  end

  it 'should login user' do
    controller.should_receive(:logged_in?).and_return(true)
    post :create
  end

  it "should not remember me" do
    post :create
    response.cookies["auth_token"].should be_nil
  end

  it "should redirect to root" do
    post :create
    response.should redirect_to('http://test.host/')
  end
  
  it "should find the app" do
    App.should_receive(:find_by_key).with('myapp').and_return(@app)
    post :create, :continue => 'http://myapp.appdrop.com/continue'
  end
  it "should redirect to the app" do
    post :create, :continue => 'http://myapp.appdrop.com/continue'
    response.should redirect_to('http://myapp.appdrop.com/continue')
  end
end

describe LoginController, "POST /login without remember me and with bad app params" do
  before(:each) do
    @user = mock_user
    User.stub!(:authenticate).and_return(@user)
    controller.stub!(:logged_in?).and_return(true)
    App.stub!(:find_by_key).and_return(nil)
  end
  it "should redirect home" do
    post :create, :continue => 'http://myapp.appdrop.com/continue'
    response.should redirect_to('http://test.host/')
  end
end

describe LoginController, "POST with password_confirmation" do

  def do_post
    post :create, :email => 'user@example.com', :password => 'password', :password_confirmation => 'password', :nickname => 'user'
  end
  
  before(:each) do
    User.stub!(:authenticate).and_return(nil)
  end
  
  describe "when the user saves" do
    before(:each) do
      @user = mock_model(User, :to_param => "1", :save => true)
      User.stub!(:new).and_return(@user)
    end
    it "should create a new user" do
      User.should_receive(:new).and_return(@user)
      do_post
    end
    it "should redirect to /" do
      do_post
      response.should redirect_to('http://test.host/')
    end
  end
  describe "when the user saves and there is app info" do
    it "should redirect to the app continue"
  end
  describe "when the user wont save (invalid)" do
    before(:each) do
      @user = mock_model(User, :to_param => "1", :save => false)
      User.stub!(:new).and_return(@user)
    end
    it "should render login again" do
      do_post
      response.should render_template(:login)
    end
  end
end

describe LoginController, "POST with remember me" do

  before(:each) do
    @user = mock_user

    @ccookies = mock('cookies')
    User.stub!(:authenticate).and_return(@user)
    controller.stub!(:logged_in?).and_return(true)
    @user.stub!(:remember_me)
    controller.stub!(:cookies).and_return(@ccookies)

    @ccookies.stub!(:[]=)
    @ccookies.stub!(:[])
    @user.stub!(:remember_token).and_return('1111')
    @user.stub!(:remember_token?).and_return(false)
    @user.stub!(:remember_token_expires_at).and_return(@exptime = Time.now)
  end

  it "should remember me" do
    @user.should_receive(:remember_me)
    post :create, :email => "derek", :password => "password", :remember_me => "1"
  end    

  it 'should create cookie' do
    @ccookies.should_receive(:[]=).with(:auth_token, { :value => '1111' , :expires => @exptime })
    post :create, :email => "derek", :password => "password", :remember_me => "1"
  end
end

describe LoginController, "POST when invalid" do

  before(:each) do
    @user = mock_user

    controller.stub!(:logged_in?).and_return(false)
    User.stub!(:authenticate).and_return(nil)
  end

  it 'should authenticate user' do
    User.should_receive(:authenticate).with('user', 'password').and_return(nil)
    post :create, :email => 'user', :password => 'password'
  end

  it 'should not login user' do
    controller.should_receive(:logged_in?).and_return(false)
    post :create
  end

  it "should not remember me" do
    post :create
    response.cookies["auth_token"].should be_nil
  end

  it "should render new" do
    post :create
    response.should render_template('login')
  end
end

describe LoginController, "logout" do

  before(:each) do
    @user = mock_user

    @ccookies = mock('cookies')
    controller.stub!(:current_user).and_return(@user)
    controller.stub!(:logged_in?).and_return(true)
    @user.stub!(:forget_me)
    controller.stub!(:cookies).and_return(@ccookies)
    @ccookies.stub!(:delete)
    @ccookies.stub!(:[])
    response.cookies.stub!(:delete)
    controller.stub!(:reset_session)
  end

  it "should get current user" do
    controller.should_receive(:current_user).and_return(@user)
    delete :destroy
  end

  it 'should forget current user' do
    @user.should_receive(:forget_me)
    delete :destroy
  end

  it "should delete token on logout" do
    @ccookies.should_receive(:delete).with(:auth_token)
    delete :destroy
  end

  it 'should reset session' do 
    controller.should_receive(:reset_session)
    delete :destroy
  end

  it "should redirect to root" do
    delete :destroy
    response.should redirect_to('http://test.host/')
  end
end
