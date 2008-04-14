class AppsController < ApplicationController

  before_filter :login_required, :only => [:new, :create, :manage]

  def index
    @apps = App.find(:all, :order => 'created_at desc')
    @title = "All Apps"
  end

  def show
    @app = App.find_by_key params[:id]
    @title = @app.name
  end

  def new
    @app = App.new
    @title = "Create a new application"
  end

  def create
    @app = App.new(params[:app])
    @app.user = current_user
    if @app.save
      redirect_to manage_app_url(@app)
    else
      render :action => 'new'
    end
  end

  def manage
    @app = App.find_by_key params[:id]
    @title = "#{@app.name} | Manage"
    unless @app.user = current_user
      render :text => "You don't own this app", :status => '403 Forbidden'
      return
    end
    @upload = Upload.new
  end

  def upload
    @app = App.find_by_key params[:id]
    @user = User.find_by_token params[:auth]
    if (@user && @app && @app.user == @user) 
      @upload = Upload.new(params[:upload])
      @upload.app = @app
      @upload.user = @user
      if (@upload.save)
        @upload.send_to_app_once
        render :text => "Upload Successful"
      else
        render :text => "Upload Error", :status => '500'
      end
    else
      render :text => "Authentication Failed - visit http://appdrop.com/home", :status => '403 Forbidden'
    end
  end

end
