require 'uri'

class PostsController < ApplicationController

  before_filter :login_required

  def index    
    @group = Mogli::Group.new({:id=>params['group_id']}, current_facebook_client)
	@group.fetch
	
	#getting posts for page 0
    @posts = @group.feed
	@page = 0
	
	if params[:next]
	  #if 'next' parameter passed - lets get page to display
	  @page = params[:next].to_i 
	  
	  # and get api url to get next or previous page
	  rest_url = (session[:page] < @page) ? session[:posts_next] : session[:posts_prev]
	  
	  # getting posts and map them to appropriate Mogli class
	  @posts = current_facebook_client.get_and_map_url(rest_url,@posts.classes)
	end
	
	# setting data to session to get url if user want to see next
	session[:posts_next] = @posts.next_url
	session[:posts_prev] = @posts.previous_url 
    session[:page] = @page
	
	# render template to string
	html = render_to_string :template => "posts/index.html.erb", :layout => false
	
	# produce json output with html, next and previous pages.
	render :json => {
	  :html => html,
	  :next => @page + 1,
	  :prev => @page > 0 ? @page - 1 : nil
    }
  end
  
  def new
    @group = Mogli::Group.new({:id=>params['group_id']}, current_facebook_client)
	@group.fetch
  end

  def create
    puts params.inspect
	
    @group = Mogli::Group.new({:id=>params['group_id']}, current_facebook_client)
	@group.fetch

    if current_facebook_user
	  puts current_facebook_client.class.post(current_facebook_client.api_path(@group.id + '/feed'),
			:query=>current_facebook_client.default_params.merge(
			           {:name => "#{current_facebook_user.name} Post a message using app!",
                        :link=>'http://staging.operations.engineyard.com/groups',
                        :message=>params['message']})).inspect
    end
    redirect_to groups_path	
  end
end
