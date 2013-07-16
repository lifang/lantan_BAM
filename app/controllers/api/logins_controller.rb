#encoding: utf-8
class Api::LoginsController < ApplicationController
     
  def check_staff
    staff = Staff.find_by_username(params[:staff_name])
    message = "用户不存在或者密码有误"
    data_type = 0
    if staff && staff.has_password?(params[:staff_password])
      if staff.position == Saff::S_HEAD[:MANAGER]
        data_type = 1
        message = "登录成功"
      else
        message = "用户权限不足"
      end
    else
      message = "用户不存在"
    end
    render :json=>{:msg=>message,:d_type=>data_type}
  end

  
end
