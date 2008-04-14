require File.dirname(__FILE__) + '/../spec_helper'

describe AppsController, "GET /apps" do
  it "should find all the apps" do
    App.should_receive(:find).with(:all, {:order=>"created_at desc"})
    get :index
  end
end

describe AppsController, "GET /apps/myapp" do
  it "should find all the apps" do
    App.should_receive(:find_by_key).with('myapp').and_return(mock_model(App, :name => 'app'))
    get :show, :id => 'myapp'
  end
end

describe AppsController, "GET /apps/new" do
  it "should render" do
    controller.stub!(:current_user).and_return(mock_user)
    get :new
    response.should be_success
  end
end

describe AppsController, "POST /apps/myapp/upload with a token that matches the apps user" do
  before(:each) do
    User.stub!(:find_by_token).and_return(@u = mock_user)
    @up = mock_model(Upload, :app= => true, :user= => true, :save => true, :send_to_app_once => true)
    Upload.stub!(:new).and_return(@up)
    @app = mock_model(App, :user => @u)
    App.stub!(:find_by_key).and_return(@app)
  end
  it "should create a new upload" do
    Upload.should_receive(:new).with({'uploaded_data' => '21478'}).and_return(@up)
    post :upload, :id => 'myapp', :auth => "mysuperauth", :upload => {'uploaded_data' => '21478'}
  end
  it "should be success" do
    post :upload, :id => 'myapp', :auth => "mysuperauth", :upload => {'uploaded_data' => '21478'}
    response.should be_success
  end
end

describe AppsController, "POST /apps/myapp/upload with a token that doesn't match the apps user" do
  before(:each) do
    User.stub!(:find_by_token).and_return(nil)
  end
  it "should fail" do
    post :upload, :id => 'myapp', :auth => "mylameauth", :upload => {'uploaded_data' => '21478'}
    response.should_not be_success
  end
end

describe AppsController, "POST /apps" do
  before(:each) do
    controller.stub!(:current_user).and_return(mock_user)    
    @app = mock_model(App, :user= => true, :save => true, :to_param => 'the-app')
    App.stub!(:new).and_return(@app)
  end
  it "should create an app" do
    App.should_receive(:new).and_return(@app)
    post :create, :name => 'App Name', :key => 'the-app'
  end
  it "should save the app" do
    @app.should_receive(:save).and_return(true)
    post :create, :name => 'App Name', :key => 'the-app'
  end
  it "should redirect to the home screen for that app" do
    post :create, :name => 'App Name', :key => 'the-app'
    response.should redirect_to('/apps/the-app/manage')
  end
end
