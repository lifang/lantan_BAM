#encoding: utf-8
require 'fileutils'
class MaterialsInOutsController < ApplicationController
  layout "mat_in_out"

  before_filter :find_store, :except => [:index, :save_cookies]
  
  def index
    @store_id = Store.first.id unless Store.first.nil?
    @staff = Staff.find(cookies[:user_id]) unless cookies[:user_id].nil?
  end
  
  def materials_in
  end

  def materials_out
  end

  def get_material
    material = Material.find_by_code(params[:code])
    if material.nil?
      render :text => 'fail'
    else
      if params[:action_name]=='m_in'
        temp_material_orders = material.material_orders.not_all_in
        material_orders = get_mo(material, temp_material_orders)
        material_in ={}
        material_in[material] = material_orders
#        if @material_orders.empty?
#          render :text => 'fail'
#        else
          render :partial => 'material_in', :locals =>{:material_in => material_in}
#        end
      else
        render :partial => 'material_out'
      end
    end
  end

  def create_materials_in
      params['mat_in_items'].split(",").each do |mat_in_item|
        mii = mat_in_item.split("_")
        mat_code = mii[0]
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
      end unless params['mat_in_items'].blank?
    render :text => "1"
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
    redirect_to "/materials_in_outs"
  end

  def save_cookies
    staff_name = Staff.find(params[:staff_id]).name
    cookies[:user_id]={:value =>params[:staff_id], :path => "/", :secure  => false}
    cookies[:user_name]={:value =>staff_name, :path => "/", :secure  => false}
    render :text => 'successful'
  end

  def upload_code
    code_file = params[:code_file]
    if code_file
      new_name = random_file_name(code_file.original_filename)
      FileUtils.mkdir_p Material::MAT_IN_PATH % @store_id
      file_path = Material::MAT_IN_PATH % @store_id + "/#{new_name}"
      File.new(file_path, 'a+')
      File.open(file_path, 'wb') do |file|
        file.write(code_file.read)
      end
      
      if File.exists?(file_path)
        @code_num = {}
        File.open(file_path, "r").each_line do |line|
          #6922233613731,10
          data = line.strip.split(',')
          @code_num[data[0]] = data[1]
        end
        p "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        p @code_num
        @material_ins = []
        materials = Material.where(:code => @code_num.keys)
        @no_material_codes = @code_num.keys - materials.map(&:code) || []
        materials.each do |material|
            temp_material_orders = material.material_orders.not_all_in
            material_orders = get_mo(material, temp_material_orders)
            mm ={}
            mm[material] = material_orders
            @material_ins << mm
        end
      end
    end
  end

  protected

  def find_store
    if cookies[:user_id].nil?
      flash[:notice] = "请先选择用户！"
      redirect_to "/materials_in_outs" and return
    end
    @staff = Staff.find(cookies[:user_id])
    @store_id = @staff.store_id
  end

  def get_mo(material,material_orders)
    mos = []
    material_orders.each do |material_order|
      mio_num = MatInOrder.where(:material_id => material.id, :material_order_id => material_order.id).sum(:material_num)
      moi_num = MatOrderItem.find_by_material_id_and_material_order_id(material.id, material_order.id).try(:material_num)
      if mio_num < moi_num
        mos <<  material_order
      end
    end
    mos
  end

end