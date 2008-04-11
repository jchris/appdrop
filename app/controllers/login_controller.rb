class LoginController < ApplicationController

  def login
    if params[:continue]
      key = /https?\:\/\/([\-a-z0-9]*)/.match(params[:continue])[1]
      @app = App.find_by_key(key)
      unless @app
        render :template => 'invalid'
        return
      end
    end
    if current_user
      render :template => 'authorize'
    else
      render :template => 'login'
    end
  end
  
  def create
    self.current_user = User.authenticate(params[:email], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me unless self.current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      continue
      flash[:notice] = "Logged in successfully"
    elsif params[:password_confirmation]
      # create a new user from the data
      @user = User.new(params.extract(:email, :password, :password_confirmation, :nickname))
      if @user.save
        continue
        flash[:notice] = "Signup successful"      
      else
        render :template => 'login'
      end
    else
      render :template => 'login'
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  private 
  
  def continue
    @app = if params[:continue]
      key = /https?\:\/\/([\-a-z0-9]*)/.match(params[:continue])[1]
      App.find_by_key(key)
    end
    if @app
      redirect_to params[:continue]
    else
      redirect_back_or_default('/')
    end
  end
end
