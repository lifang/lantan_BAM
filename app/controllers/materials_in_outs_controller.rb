#encoding: utf-8
class MaterialsInOutsController < ApplicationController
  layout "mat_in_out"

  before_filter :find_store, :except => [:index, :save_cookies]
  
  def index
   @store_id = params[:store_id]
   @staff = Staff.find(cookies[:user_id]) unless cookies[:user_id].nil?
  end
  
  def materials_in
  end

  def materials_out
  end

  def get_material
    @material = Material.find_by_code(params[:code])
    if @material.nil?
      render :text => 'no results'
      @material_orders = []
    else
      if params[:action_name]=='m_in'
        @material_orders = @material.material_orders
        render :partial => 'material_in'
      else
        render :partial => 'material_out'
      end
    end
  end

  def create_materials_in
    if params['material_order'].nil?
      flash[:notice] = '请录入商品！'
      redirect_to "/stores/#{@store_id}/materials_in" and return
    end
    params['material_order'].values.each do |mo|
      mat_in_order = MatInOrder.where(:material_id => mo[:material_id], :material_order_id => mo[:material_order_id])
      if mat_in_order.empty?
        mat_in_order = MatInOrder.create(mo)
      else
        mat_in_order.update_attributes(:material_num => mat_in_order + mo[:material_num].to_i)
      end
      if mat_in_order.save
        material = mat_in_order.material
        material_order = mat_in_order.material_order
        if material_order.mat_order_items.sum(:material_num)<=material_order.mat_in_orders.sum(:material_num)
          material_order.m_status = 3
          material_order.save
        end
        material.storage += mat_in_order.material_num
        material.save
      end
    end
    flash[:notice] = '商品已成功入库！'
    redirect_to "/stores/#{@store_id}/materials_in_outs"
  end

  def create_materials_out
    if params['material_order'].nil?
      flash[:notice] = '请录入商品！'
      redirect_to "/stores/#{@store_id}/materials_out" and return
    end
    params['material_order'].values.each do |mo|
      mat_out_order = MatOutOrder.create(mo)
      if mat_out_order.save
        material = Material.find(mat_out_order.material_id)
        material.storage -= mat_out_order.material_num
        material.save
      end
    end
    flash[:notice] = '商品已成功出库！'
    redirect_to "/stores/#{@store_id}/materials_in_outs"
  end

  def save_cookies
    staff_name = Staff.find(params[:staff_id])
    cookies[:user_id]={:value =>params[:staff_id], :path => "/", :secure  => false}
    cookies[:user_name]={:value =>staff_name, :path => "/", :secure  => false}
    render :text => 'successful'
  end

  protected

  def find_store
    if cookies[:user_id].nil?
      flash[:error] = "请先选择用户！"
      redirect_to request.referrer and return
    end
    @staff = Staff.find(cookies[:user_id])
    @store_id = @staff.store_id
  end
end