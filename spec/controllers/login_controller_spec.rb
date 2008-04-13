require File.dirname(__FILE__) + '/../spec_helper'

describe "Routes for the LoginController should map" do
  controller_name :login

  it "get login" do
    route_for(:controller => "login", :action => "login").should == "/login"
  end
  
  it "post login" do
    route_for(:controller => "login", :action => "create").should == "/login"
  end
  
end


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

  describe "with an current session and an app" do
    before(:each) do
      @user = mock_model(User)
      controller.stub!(:current_user).and_return @user
      @app = mock_model(App)
      App.stub!(:find_by_key).and_return(@app)
    end
    it "should render the authorize page" do
      get :login, :continue => "http://not-fug-this.appspot.com/_ah/login%3Fcontinue%3Dhttp://not-fug-this.appspot.com/"
      response.should render_template(:authorize)
    end
  end
end

describe LoginController, "POST /authorize while logged in with app info" do
  before(:each) do
    @user = mock_user
    controller.stub!(:current_user).and_return @user
    @app = mock_model(App)
    App.stub!(:find_by_key).and_return(@app)
    @auth = mock_model(AuthToken, :token => 'authtoken')
    AuthToken.stub!(:create).and_return(@auth)
  end
  it "should create an auth token" do 
    AuthToken.should_receive(:create).with(:user => @user, :app => @app).and_return(@auth)
    post :authorize, :continue => "http://not-fug-this.appspot.com/_ah/login"
  end
  it "should redirect to the app continue page" do
    post :authorize, :continue => "http://not-fug-this.appspot.com/_ah/login"
    response.should redirect_to('http://not-fug-this.appspot.com/_ah/login?auth=authtoken')
  end
end

describe LoginController, "GET /auth?token=validtoken" do
  before(:each) do
    @auth = mock_model(AuthToken, :used? => false, :used= => true, :save => true, :token => 'validtoken', :user => @u1 = mock_user, :app => @app = mock_model(App, :user => @u2 = mock_model(User)))
    AuthToken.stub!(:find_by_token).and_return(@auth)
    App.stub!(:find_by_key).and_return(@app)
  end
  it "should find the token" do
    AuthToken.should_receive(:find_by_token).with('validtoken').and_return(@auth)
    get :auth, :token => 'validtoken', :app => 'http://myapp.appdrop.com/'
  end
  it "should return json of the user" do
    get :auth, :token => 'validtoken', :app => 'http://myapp.appdrop.com/'
    response.body.should match(/flappy/)
    response.body.should match(/false/)
  end
  it "should say admin yes if the user owns the app" do
    @app.stub!(:user).and_return(@u1)
    get :auth, :token => 'validtoken', :app => 'http://myapp.appdrop.com/'
    response.body.should match(/true/)
  end
  it "should mark the token used" do
    @auth.should_receive(:used=).with(true)
    get :auth, :token => 'validtoken', :app => 'http://myapp.appdrop.com/'
  end  
end

describe LoginController, "GET /auth?token=usedtoken&app=http://myapp.appdrop.com/" do
  before(:each) do
    @auth = mock_model(AuthToken, :used? => true, :used= => true, :save => true, :token => 'validtoken', :user => mock_user, :app => @app = mock_model(App))
    AuthToken.stub!(:find_by_token).and_return(@auth)
    App.stub!(:find_by_key).and_return(@app)
  end
  it "should barf" do
    get :auth, :token => 'validtoken', :app => 'http://myapp.appdrop.com/'
    response.should_not be_success
  end
end

describe LoginController, "GET /auth?token=wrongapp&app=http://myapp.appdrop.com/" do
  before(:each) do
    @auth = mock_model(AuthToken, :used? => false, :used= => true, :save => true, :token => 'validtoken', :user => mock_user, :app => @app = mock_model(App))
    AuthToken.stub!(:find_by_token).and_return(@auth)
    @app2 = mock_model(App)
    App.stub!(:find_by_key).and_return(@app2)
  end
  it "should barf" do
    get :auth, :token => 'wrongapp', :app => 'http://myapp.appdrop.com/'
    response.should_not be_success
  end
end

describe LoginController, "POST /authorize while logged in with bad app info" do
  before(:each) do
    @user = mock_model(User)
    controller.stub!(:current_user).and_return @user
    App.stub!(:find_by_key).and_return(nil)
  end
  it "should barf" do
    post :authorize, :continue => "http://not-fug-this.appspot.com/_ah/login%3Fcontinue%3Dhttp://not-fug-this.appspot.com/"
    response.should_not be_success
  end
end

describe LoginController, "POST /login without remember me and with app params" do

  before(:each) do
    @user = mock_user
    User.stub!(:authenticate).and_return(@user)
    controller.stub!(:logged_in?).and_return(true)
    @app = mock_model(App, :valid? => true)
    App.stub!(:find_by_key).and_return(@app)
    @auth = mock_model(AuthToken, :token => 'authtoken')
    AuthToken.stub!(:create).and_return(@auth)
  end

  it 'should authenticate user' do
    User.should_receive(:authenticate).with('user', 'password').and_return(@user)
    post :create, :user => {:email => 'user', :password => 'password'}
  end

  it 'should login user' do
    controller.should_receive(:logged_in?).and_return(true)
    post :create, :user => {}
  end

  it "should not remember me" do
    post :create, :user => {}
    response.cookies["auth_token"].should be_nil
  end

  it "should redirect to root without app params" do
    post :create, :user => {}
    response.should redirect_to('http://test.host/')
  end
  
  it "should find the app" do
    App.should_receive(:find_by_key).with('myapp').and_return(@app)
    post :create, :continue => 'http://myapp.appdrop.com/continue', :user => {}
  end
  it "should redirect to the app with auth token" do
    post :create, :continue => "http://myapp.appdrop.com/login?continue=http://myapp.appdrop.com/", :user => {}
    response.should redirect_to("http://myapp.appdrop.com/login?continue=http://myapp.appdrop.com/&auth=#{@auth.token}")
  end
  it "should create an auth token" do 
    AuthToken.should_receive(:create).with(:user => @user, :app => @app).and_return(@auth)
    post :create, :continue => "http://myapp.appdrop.com/login?continue=http://myapp.appdrop.com/", :user => {}
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
    post :create, :continue => 'http://myapp.appdrop.com/continue', :user => {}
    response.should redirect_to('http://test.host/')
  end
end

describe LoginController, "POST with password_confirmation" do

  def do_post
    post :create, :user => {:email => 'user@example.com', :password => 'password', :password_confirmation => 'password', :nickname => 'user'}
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
    before(:each) do
      @user = mock_user
      User.stub!(:new).and_return(@user)
      @app = mock_model(App, :valid? => true)
      App.stub!(:find_by_key).and_return(@app)
      @auth = mock_model(AuthToken, :token => 'authtoken')
      AuthToken.stub!(:create).and_return(@auth)
    end
    it "should redirect to the app continue" do
      post :create, :user => {:email => 'user@example.com', :password => 'password', :password_confirmation => 'password', :nickname => 'user'}, :continue => 'http://example.appdrop.com'
      response.should redirect_to("http://example.appdrop.com?auth=#{@auth.token}")
    end
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
    post :create, :user => {:email => "derek", :password => "password", :remember_me => "1"}
  end    

  it 'should create cookie' do
    @ccookies.should_receive(:[]=).with(:auth_token, { :value => '1111' , :expires => @exptime })
    post :create, :user => {:email => "derek", :password => "password", :remember_me => "1"}
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
    post :create, :user => {:email => 'user', :password => 'password'}
  end

  it 'should not login user' do
    controller.should_receive(:logged_in?).and_return(false)
    post :create, :user => {}
  end

  it "should not remember me" do
    post :create, :user => {}
    response.cookies["auth_token"].should be_nil
  end

  it "should render new" do
    post :create, :user => {}
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
