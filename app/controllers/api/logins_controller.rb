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
      render :json=>{:data=>0,:login_staff=>staff.id,:login_name=>staff.name}
    else
      render :json=>{:data=>1}
    end
  end

  def upload_img
    staff = Staff.find(params[:staff_id])
    begin
      photo = params[:login_photo]
      staff.photo = "/uploads/#{params[:store_id]}/#{staff.id}/#{staff.id}_#{Constant::STAFF_PICSIZE.first}."+photo.original_filename.split(".").reverse[0] unless photo.nil?
      staff.operate_picture(photo,"#{staff.id}.#{photo.original_filename.split(".").reverse[0]}", "update")
      render :json=>{:data=>0}
    rescue
      render :json=>{:data=>1}
    end
  end

  def staff_checkin
    staff = Staff.find(params[:staff_id])
    if staff and staff.work_records.where("current_day=#{Time.now.strftime("%Y%m%d").to_i}").blank?
      Station.set_station(staff.store_id,staff.id,staff.level) if staff.type_of_w == Staff::S_COMPANY[:TECHNICIAN]
      WorkRecord.create(:current_day=>Time.now.strftime("%Y%m%d").to_i,:attendance_num=>1,:staff_id=>staff.id,:store_id=>staff.store_id)
      render :json=>{:data=>0}
    else
      render :json=>{:data=>1}
    end
  end

  
end
