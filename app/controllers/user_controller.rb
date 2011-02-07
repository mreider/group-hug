class UserController < ApplicationController

  def login
    # display readme
	myfile = File.open("README.textile")
	readme = String.new
	myfile.each {|line| readme << line}
	@readme_html = readme.markdown.html_safe
  end

  def create
    @user = User.find_by_email(params[:email])
    create_via_facebook_connect if @user.nil?

    if @user != nil 
      session[:user_id] = @user.id
      redirect_to url_for(groups_path)
    else
      flash[:error] = "Unable to log you in"
      render :action=>"login"
    end
  end

  def create_via_facebook_connect
    if current_facebook_user 
      #look for an existing user
      @user = User.find_by_facebook_id(current_facebook_user.id)	  
      if @user.nil?
        #if one isn't found - fetch user data via Mogli lib and create new user
        current_facebook_user.fetch
	    @user = User.new(:name => current_facebook_user[:name], :email => current_facebook_user[:email], :facebook_id => current_facebook_user[:id], :facebook_session_key => current_facebook_client.access_token)
		@user.save
      end
    end
  end

  def prereqs
  end
  
  def privacy
  end
  
  def tos
  end

end
