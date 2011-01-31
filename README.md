Rails Tutorial + Facebook Connect
=================================

* Install rails:
	gem install rails
* Create rails app:
	rails new fbcomments
* Install facebooker2 as a plugin in your rails app.
	script/rails plugin install git://github.com/mmangino/facebooker2.git
* Create facebook application at http://www.facebook.com/developers/createapp.php and set the site URL to your application URL. For example, ours is http://icanhazrails.com/

* Create config/facebooker.yml with the appropriate environment.

	development:
		app_id: <your application id>
		secret: <your application secret>
		api_key: <your application key>
		
  and possible test/production environment

6. Create config/initializers/facebooker2.rb and place the following line in it

	Facebooker2.load_facebooker_yaml

7. Add the following line to your app/controllers/application_controller.rb

	include Facebooker2::Rails::Controller

5. Update your rails applications to use the rails helpers. Lets put this code to page layout(views/layouts/application.html.erb) to display login button on every page or if user already loged in - his name

	<% # include JavaScript to use facebook connect%>
	<%= fb_connect_async_js %> 

	<% if current_facebook_user !=nil %>
		<%= "Welcome #{@current_user.name}!"  if @current_user !=nil %>
		<%= fb_logout_link("Logout", request.url) %><br />
	<% else
		# we must explicitly request permissions for facebook user fields.
		# we need to get user's email, groups, stream posts and post to groups or stream
		# also fb_login_and_redirect first parameter is redirect url after login attempt
		%>
		<%= fb_login_and_redirect( url_for(:action => 'create', :controller => 'home', :only_path => false),
			:perms => 'email,user_groups,read_stream, publish_stream') %>
	<% end %>

6. Create model to store application users

	rails generate model User
	
  and create migration like this:
  
    class CreateUsers < ActiveRecord::Migration
	  def self.up
		create_table :users do |t|
		  t.string :email, :name, :facebook_id, :facebook_session_key
		  t.timestamps
		end
	  end

	  def self.down
		drop_table :users
	  end
    end

  then run migration via
  
  rake db:migrate
  
7. Create Home controller and put there login and create user action
   
      rails generate controller Home

   just display empty page
  
	  def login
	  end

   view can be empty - login button already defined in the layout
  
   create action must get parameters passed by facebook after user login
   and create new user if it not exists. we can do it such way:
   
	  def create
		@user = User.find_by_email(params[:email])
		create_via_facebook_connect if @user.nil?

		if @user != nil 
		  session[:user_id] = @user.id
		  redirect_to url_for(groups_path)
		  session[:return_to]=nil
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

8. After successful login users will go to groups controller.  Lets create it and setup routes:

       rails generate controller Groups
	  
   and edit config/routes.rb to add
   
       resources :groups 
   
   set home page to login
   
       root :to => "home#login"

   and allow to use '<controller>/<action>'	routes. Just uncomment last route
   
       match ':controller(/:action(/:id(.:format)))'
	   
9. Add methods to ApplicationController to check if user is logged in and determine user id:

	  def current_user
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

10. Implement GroupsController

	  def index 
		#get current users groups
		@groups = current_facebook_user.groups
		
		#determine selected user group or get first group id if default group is not selected
		@default_group = @current_user.default_group
		@default_group = @groups.first.id if @default_group.nil? && @groups.first != nil
	  end
	
11. Implement goups view in app/views/groups/index.html.erb


		<select name="group" id="group" >
		<% @groups.each do |group| %>
		 <option value="<%=group.id%>" <%= 'selected' if @default_group == group.id %>><%=group.name%></option>
		<% end %>
		</select>

		<br/>
		<input id="def_group" name="def_group" type="checkbox" selected="false" /> Default group <br/>

		<div id="posts_container" >Posts</div>
	
12. Install jQuery via instructions at https://github.com/lleger/Rails-3-jQuery/ 

13. Add placeholder for JavaScript at layout header

	  <script> 
	  <%= yield (:javascript) %>
	  </script>
	
	and create JavaScript to save default group
		
		<% content_for (:javascript) do %>
		$(document).ready(function() {

		  $('#def_group').bind('change', function() {
			var group_id = $(this).is(':checked') ? $('#group').val() : 'nil'
			$.post('/groups/default/' + group_id ,  function() {
			  alert ('Default group was saved');
			});
		  });
		 
		});  
		<% end %>

     So now we have combo box with all user groups.
	 
14. Implement default group save in GroupsController

	  def default
		render :json => { :result => @current_user.update_attributes(:default_group => params['id'] == 'nil' ? nil : params['id']) }
	  end

15. Implement Posts in current group displaying. 
     
	 rails generate controller Groups
	 
	Lets use nested resouces to relate groups and posts. Setup routes this way:
	
	  resources :groups do
		resources :posts
	  end
	
16. Call Posts List in groups view via jQuery:

    Implement 'change' event:

	  $('#group').bind('change', function() {
		$('#posts_container').load('/groups/' + $(this).val() + '/posts',  function() {
		  FB.XFBML.parse(document.getElementById('posts_container'));
		});
	  });

	And implement default group display on page load:
	  
	  $('#posts_container').load('/groups/<%=@default_group%>/posts',  function() {
		FB.XFBML.parse(document.getElementById('posts_container'));
  
	  });

	Posts controller will return user images in FBML, so we must parse FBML via FB.XFBML.parse
	 
17. Posts list in selected group to insert via AJAX:

	  def index    
		@group = Mogli::Group.new({:id=>params['group_id']}, current_facebook_client)
		@group.fetch
		@posts = @group.feed
		render :layout => false
	  end

     view template can be like:
	 
	<% @posts.each do |post| %>

	<div style="clear:both">
	  <span style="float:left;width:55px">
		<fb:profile-pic uid="<%=post.from.id%>" linked="false" size="q"></fb:profile-pic>
	  </span>
	  <span>
		<%=post.message%><br/> 
		<%=time_ago_in_words(post.updated_time) %> ago
	  </span>
	</div>

	<% end %>
	 

18. Link to post new message used nested resource path:

	<%= link_to "Post", url_for(new_group_post_path(@group.id)) %>	
	
19. Display form to post message to group. PostsController get current group to display name:

	  def new
		@group = Mogli::Group.new({:id=>params['group_id']}, current_facebook_client)
		@group.fetch
	  end

	and simple view:
	
	<h1>Post a wall message to: <%= @group.name %></h1>

	<% form_tag  url_for(group_posts_path(@group.id)), :method=>:post do -%>
	 
	  
	  <%= hidden_field_tag 'group_id', @group.id %>
	  
	  <div class="field">
		<%= text_area_tag 'message', nil, :rows => 10, :cols => 60 %>
	  </div>
	  <div class="field">
		<%= check_box_tag 'send_via_email', 'yes', true %> Send the whole group an email
	  </div>
	  <div class="actions">
		<%= submit_tag 'Save' %>
	  </div>
	<% end -%>
	 
	<%= link_to 'Back', url_for(groups_path) %>

20. Form submited to create action

	  def create
		@group = Mogli::Group.new({:id=>params['group_id']}, current_facebook_client)
		@group.fetch

		if current_facebook_user
		  current_facebook_client.class.post(current_facebook_client.api_path(@group.id + '/feed'),
				:query=>current_facebook_client.default_params.merge(
						   {:name => "#{current_facebook_user.name} Post a message using app!",
							:link=>'http://staging.operations.engineyard.com/groups',
							:message=>params['message']})).inspect
		end
		redirect_to groups_path	
	  end

21. Run your app via 'rackup' command