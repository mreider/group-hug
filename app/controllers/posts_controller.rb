require 'uri'

class PostsController < ApplicationController

  before_filter :login_required

  def index    
    @group = Mogli::Group.new({:id=>params['group_id']}, current_facebook_client)
	@group.fetch
    @posts = @group.feed
	
	@page = 0
	#@posts.fetch_next
	if params[:next]
	  @page = params[:next].to_i 
	  #rest_url = params[:next] + '&limit=' + params[:limit]
	  #rest_url += '&until=' +  URI.unescape(params[:until]) if params[:until]
	  #rest_url += '&since=' +  URI.unescape(params[:since]) if params[:since]
	  
	  puts 'Next page:' + @page.to_s
	  
	  rest_url = (session[:page] < @page) ? session[:posts_next] : session[:posts_prev]
	  @posts = current_facebook_client.get_and_map_url(rest_url,@posts.classes)
	  #puts @posts.inspect	  
	end
	session[:posts_next] = @posts.next_url
	session[:posts_prev] = @posts.previous_url 
    session[:page] = @page
	
	html = render_to_string :template => "posts/index.html.erb", :layout => false
	
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
	#@posts = @group.feed

    #flash[:notice] = "Note sent to #{note.recipient.email}"
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
