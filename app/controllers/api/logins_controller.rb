#encoding: utf-8
class Api::LoginsController < ApplicationController

  #店长登录
  def check_staff
    staff = Staff.find_by_username(params[:staff_name])
    message = "用户不存在或者密码有误"
    data_type = 1
    staffs =[]
    if staff && staff.has_password?(params[:staff_password])
      if staff.position == Staff::S_HEAD[:MANAGER]
        data_type = 0
        message = "登录成功"
        Staff.where("store_id=#{staff.store_id} and status=#{Staff::STATUS[:normal]} and position in (#{Staff::S_HEAD[:NORMAL]},#{Staff::S_HEAD[:MANAGER]})").each{|staff|
          hash={};hash["id"]=staff.id;hash["name"]=staff.name;hash["photo"]=staff.photo;staffs << hash}
      else
        message = "用户没有权限"
      end
      render :json=>{:msg=>message,:d_type=>data_type,:store_id=>staff.store_id,:staffs=>staffs}
    else
      message = "用户不存在或者密码不正确"
      render :json=>{:msg=>message,:d_type=>data_type}
    end
    
  end


  #签到时无法识别的人脸要做登录处理
  def staff_login
    staff = Staff.find_by_username_and_store_id(params[:login_name],params[:store_id])
    if staff && staff.has_password?(params[:login_password])
      photo = params[:login_photo]
      encrypt_name = random_file_name(photo.original_filename)
      @staff.photo = "/uploads/#{@store.id}/#{@staff.id}/"+encrypt_name+"_#{Constant::STAFF_PICSIZE.first}."+photo.original_filename.split(".").reverse[0] unless photo.nil?
      staff.operate_picture(photo,encrypt_name +"."+photo.original_filename.split(".").reverse[0], "create")
      render :json=>{:data=>0,:login_staff=>staff.id,:msg=>"员工信息更新完成，请重新签到"}
    else
      render :json=>{:data=>1,:msg=>"员工信息不存在，请录入！"}
    end
  end

  def staff_checkin
    staff = Staff.find(params[:staff_id])
    if staff
      Station.set_station(staff.store_id,staff.id,staff.level) if staff.type_of_w == Staff::S_COMPANY[:TECHNICIAN]
      WorkORecord.create(:current_day=>Time.now.strftime("%Y%m%d").to_i,:attenance_num=>1,:staff_id=>staff.id,:store_id=>staff.store_id)
      message = "签到成功"
    else
      message = "签到不成功,用户不存在"
    end
    render :json=>{:msg=>message}
  end

  
end
