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
      render :text => 'fail'
    else
      if params[:action_name]=='m_in'
        @material_orders = @material.material_orders
        if @material_orders.empty?
          render :text => 'fail'
        else
          render :partial => 'material_in'
        end
      else
        render :partial => 'material_out'
      end
    end
  end

  def create_materials_in
    if params['mat_in_items']
      params['mat_in_items'].split(",").each do |mat_in_item|
        mii = mat_in_item.split("_")
        mat_code = mii[0].to_i
        mo_code = mii[1]
        num = mii[2]
        material = Material.find_by_code_and_status_and_store_id mat_code,Material::STATUS[:NORMAL],@store_id
        material_order = MaterialOrder.find_by_code mo_code
        mat_in_order = MatInOrder.create({:material => material, :material_order => material_order,
            :material_num => num, :price => material.price, :staff_id => @staff.id
          })
        if mat_in_order.save
          if material_order.check_material_order_status
            material_order.m_status = 3
            material_order.save
          end
          material.storage += mat_in_order.material_num
          material.save
        end

      end
    end
    render :text => "success"
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


  #判断订货数目与入库数目是否一致
  def check_nums
    num = params[:num].to_i
    material = Material.find_by_code_and_status_and_store_id params[:barcode],Material::STATUS[:NORMAL],@store_id
    material_order = MaterialOrder.find_by_code params[:mo_code]
    mio_num = MatInOrder.where(:material_id => material.id, :material_order_id => material_order.id).sum(:material_num)
    moi_num = MatOrderItem.find_by_material_id_and_material_order_id(material.id, material_order.id).try(:material_num)
    render :text => !mio_num.nil? && (mio_num+num) >= moi_num ? 1 : 0
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