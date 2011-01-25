class ApplicationController < ActionController::Base
  include Facebooker2::Rails::Controller

  protect_from_forgery
  
  def current_user
    #@current_user = current_facebook_user.fetch
    #puts "Session: #{session[:user_id]}"
    #puts "current_facebook_user: #{current_facebook_user.inspect}"
    #return current_facebook_user
  
    if session[:user_id]
      @current_user ||= User.find(session[:user_id])
    elsif current_facebook_user and @current_user.nil?
      @current_user = User.find_by_facebook_id(current_facebook_user.id)
    end
  end
  
  helper_method :current_user
  
  
  def login_required
    if current_user.nil?
      flash[:notice] = "You must login to access this page"
      session[:return_to] = request.request_uri
      redirect_to :controller =>'home', :action =>'login' and return
    end
  end
  
  
end
