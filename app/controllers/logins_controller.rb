#encoding: utf-8
class LoginsController < ApplicationController
  def index
    
  end

  def create
    @staff = Staff.find_by_username(params[user_name])
    if  @staff.nil? or !@staff.has_password?(params[:user_password])
      flash[:error] = "用户名或密码错误"
      redirect_to request.referer
    else
      cookies[:user_id]={:value =>@staff.id, :path => "/", :secure  => false}
      cookies[:user_name]={:value =>@staff.name, :path => "/", :secure  => false}
      cookie_role(cookies[:user_id])
      if is_admin? or is_manager? or is_staff?
        #redirect_to "/customers"
      else
        cookies.delete(:user_id)
        cookies.delete(:user_name)
        cookies.delete(:user_roles)
        flash[:error] = "抱歉，你没有访问权限"
        redirect_to request.referer
      end
    end
  end
end
