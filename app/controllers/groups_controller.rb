class GroupsController < ApplicationController

  before_filter :login_required

  def index 
    #get current users groups
    @groups = current_facebook_user.groups
	
	#determine selected user group or get first group id if default group is not selected
	puts @current_user.inspect
	@default_group = @current_user.default_group
	@default_group = @groups.first.id if @default_group.nil? && @groups.first != nil
	if (params[:current_group] != nil)
	  @current_group = params[:current_group]
	else 
	  @current_group = @default_group
	end
  end

  def default
	render :json => { :result => @current_user.update_attributes(:default_group => params['id'] == 'nil' ? nil : params['id']) }
  end

  end
