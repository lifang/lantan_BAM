#encoding: utf-8
class RolesController < ApplicationController
  layout "role"
  before_filter :sign?

  def index
    @roles = Role.all
    @menus = Menu.find_by_sql("select m.*,rmr.id relation_id,rmr.role_id from menus m
      left join role_menu_relations rmr on m.id=rmr.menu_id and rmr.role_id=#{params[:role_id].to_i}") if params[:role_id]
    @role_model_relations = RoleModelRelation.find_all_by_role_id params[:role_id].to_i if params[:role_id]
    respond_to do |f|
      f.html
      f.js
    end
  end

  def update
    puts params[:name],params[:id]
    role = Role.find_by_id params[:id]
    if role
      role.update_attribute(:name, params[:name])
    end
    render :json => {:status => 0}
  end

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

  def staff
    str = "store_id=#{params[:store_id]} and status =#{Staff::STATUS[:normal]} "
    if params[:name]
      str += " and name like '%#{params[:name]}%'"
    end
    @staffs = Staff.paginate(:conditions => str,
                             :page => params[:page], :per_page => Constant::PER_PAGE)
    @roles = Role.all
    respond_to do |f|
      f.html
      f.js
    end
  end

  def set_role
    puts "set role",params[:m_ids],params[:f_ids],params[:role_id]
    status = 0
    if params[:role_id]
      RoleMenuRelation.transaction do
        begin
          role = Role.find_by_id params[:role_id].to_i
          if role
            RoleMenuRelation.delete_all("role_id=#{role.id}")
            #RoleModelRelation.delete_all("role_id=#{role.id}")
          end
          params[:m_ids].split(",").each do |m_id|
            model_relation = RoleMenuRelation.create(:role_id => role.id, :menu_id => m_id.to_i)
            if model_relation && model_relation.menu
              params[:f_ids].split(",").each do |f_id|
                if f_id.split("_")[0] == model_relation.menu.controller
                  role_model = RoleModelRelation.find_by_role_id_and_model_name role.id,f_id.split("_")[0]
                  RoleModelRelation.create(:role_id => role.id, :model_name => f_id.split("_")[0], :num => f_id.split("_")[1]) if role_model.nil?
                  role_model.update_attribute(:num, role_model.num | f_id.split("_")[1].to_i) if role_model
                end
              end
            end
          end
          status = 1
        rescue
          status = 2
        end
      end
    end
    render :json => {:status => status}
  end

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
