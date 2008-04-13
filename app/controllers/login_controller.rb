class LoginController < ApplicationController

  before_filter :login_required, :only => [:authorize, :destroy]

  def login
    if params[:continue]
      key = /https?\:\/\/([\-a-z0-9]*)/.match(params[:continue])[1]
      @app = App.find_by_key(key)
      unless @app
        render :action => 'invalid', :status => '404 Not Found'
        return
      end
    end
    if current_user
      unless @app
        redirect_back_or_default('/')
        return
      end
      @title = "Authorize Login"
      render :action => 'authorize'
    else
      @title = "Login or Signup"
      @user = User.new
      render :action => 'login'
    end
  end
  
  def authorize
    key = /https?\:\/\/([\-a-z0-9]*)/.match(params[:continue])[1]
    @app = App.find_by_key(key)
    unless @app
      render :action => 'invalid', :status => '404 Not Found'
      return
    end
    continue
  end
  
  def auth
    @auth = AuthToken.find_by_token params[:token]
    raise ActiveRecord::RecordNotFound unless @auth
    key = /https?\:\/\/([\-a-z0-9]*)/.match(params[:app])[1]
    @app = App.find_by_key(key)
    if ((@app != @auth.app) || (@auth.used?))
      render :text => "Invalid or Expired Token", :status => '403 Forbidden'
      return
    end
    user = @auth.user
    @auth.used = true
    @auth.save
    # todo - how do we know the app requesting it so we can do admin?
    result = {:nickname => user.nickname, :email => user.email, :admin => (@app.user == @auth.user)}
    render :json => result
  end
  
  def create
    self.current_user = User.authenticate(params[:user][:email], params[:user][:password])
    if logged_in?
      if params[:user][:remember_me] == "1"
        self.current_user.remember_me unless self.current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      flash[:notice] = "Logged in successfully."
      continue
    elsif !params[:user][:password_confirmation].blank?
      @user = User.new(params[:user])
      if @user.save
        flash[:notice] = "Signup successful. Welcome to AppDrop!"
        self.current_user = @user
        @user.remember_me if params[:user][:remember_me] == "1"
        continue
      else
        render :action => 'login'
      end
    else
      @user = User.new
      flash[:notice] = "Login failed. Try again?"
      render :action => 'login'
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    continue
  end

  private 
  
  def continue
    @app = if params[:continue]
      key = /https?\:\/\/([\-a-z0-9]*)/.match(params[:continue])[1]
      App.find_by_key(key)
    end
    if @app
      # setup create auth token and append it
      @auth = AuthToken.create :user => current_user, :app => @app
      url = URI.parse(params[:continue])
      if url.query
        url.query << "&auth=#{@auth.token}"
      else
        url.query = "auth=#{@auth.token}"
      end
      redirect_to url.to_s
    else
      redirect_back_or_default('/')
    end
  end
end
