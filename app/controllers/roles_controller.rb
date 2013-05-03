#encoding: utf-8
class RolesController < ApplicationController
  layout "role"
  before_filter :sign?

  #角色列表
  def index
    @roles = Role.all
    @role_id = params[:role_id] if params[:role_id]
    @menus = Menu.all
    @role_menu_relation_menu_ids = RoleMenuRelation.where(:role_id => @role_id).map(&:menu_id) if @role_id
    respond_to do |f|
      f.html
      f.js
    end
  end

  #修改角色名称
  def update
    puts params[:name],params[:id]
    role = Role.find_by_id params[:id]
    if role
      role.update_attribute(:name, params[:name])
    end
    render :json => {:status => 0}
  end

  #添加角色
  def create
    role = Role.find_by_name params[:name]
    status = 0
    if role.nil?
      Role.create(:name => params[:name])
    else
      status = 1
    end
    render :json => {:status => status}
  end

  #查询员工
  def staff
    str = "store_id=#{params[:store_id]} and status =#{Staff::STATUS[:normal]} "
    if params[:name]
      str += " and name like '%#{params[:name]}%'"
    end
    @staffs = Staff.includes(:staff_role_relations => :role).paginate(:conditions => str,
      :page => params[:page], :per_page => Constant::PER_PAGE)
    @roles = Role.all
    respond_to do |f|
      f.html
      f.js
    end
  end

  #角色功能设定
  def set_role
    if params[:role_id]
      role_id = params[:role_id]
      role = Role.find role_id
      if params[:menu_checks] #处理角色-菜单设置
        menus = Menu.where(:id => params[:menu_checks])
        role.menus = menus
      end
      if params[:model_nums] #处理角色-功能模块设置
        params[:model_nums].each do |controller, num|
          role_model_relation = RoleModelRelation.where(:role_id => role_id, :model_name => controller)
          if role_model_relation.empty?
            RoleModelRelation.create(:num => num.map(&:to_i).sum, :role_id => role_id, :model_name => controller)
          else
            role_model_relation.first.update_attributes(:num => num.map(&:to_i).sum)
          end
        end
        deleted_menus = RoleModelRelation.where(:role_id => role_id).map(&:model_name) - params[:model_nums].keys
        RoleModelRelation.delete_all(:role_id => role_id, :model_name => deleted_menus) unless deleted_menus.empty?
      end
    end
    flash[:notice] = "设置成功!"
    redirect_to store_roles_url(params[:store_id])
  end

  #删除角色
  def destroy
    role = Role.find_by_id params[:id].to_i
    status = 0
    if role
      puts role.name
      Role.transaction do
        begin
          RoleMenuRelation.delete_all("role_id=#{role.id}")
          RoleModelRelation.delete_all("role_id=#{role.id}")
          StaffRoleRelation.delete_all("role_id=#{role.id}")
          role.destroy
          status = 1
        rescue
          status = 2
        end
      end

    end
    render :json => {:status => status}
  end

  #用户角色设定
  def reset_role
    staff = Staff.find_by_id params[:staff_id].to_i
    status = 0
    if staff
      StaffRoleRelation.delete_all("staff_id=#{staff.id}")
      params[:roles].split(",").each do |r_id|
        StaffRoleRelation.create(:staff_id => staff.id,:role_id => r_id)
      end
      status = 1
    end
    render :json => {:status => status}
  end
end
