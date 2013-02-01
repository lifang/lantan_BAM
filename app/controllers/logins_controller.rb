#encoding: utf-8
class LoginsController < ApplicationController
  def index
    render :index, :layout => false
  end

  def create
    @staff = Staff.find_by_username(params[:user_name])
    if  @staff.nil? or !@staff.has_password?(params[:user_password])
      flash[:error] = "用户名或密码错误"
      redirect_to "/"
    else
      cookies[:user_id]={:value =>@staff.id, :path => "/", :secure  => false}
      cookies[:user_name]={:value =>@staff.name, :path => "/", :secure  => false}
      session_role(cookies[:user_id])
      if is_admin? or is_boss? or is_manager? or is_staff?
        redirect_to "/stores/#{@staff.store_id}/welcomes"
      else
        cookies.delete(:user_id)
        cookies.delete(:user_name)
        cookies.delete(:user_roles)
        cookies.delete(:model_role)
        flash[:error] = "抱歉，您没有访问权限"
        redirect_to "/"
      end
    end
  end
end
