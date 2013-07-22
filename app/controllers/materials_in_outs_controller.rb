#encoding: utf-8
require 'fileutils'
class MaterialsInOutsController < ApplicationController
  before_filter :sign?
  before_filter :find_store
  layout "mat_in_out", :except => [:create_materials_in]

  def index
  end
  
  def materials_in
  end

  def materials_out
  end

  def get_material
    material = Material.normal.find_by_code_and_store_id(params[:code], @store.id)
    if material.nil?
      render :text => 'fail'
    else
      if params[:action_name]=='m_in'
        temp_material_orders = material.material_orders.not_all_in
        material_orders = get_mo(material, temp_material_orders)
        material_in ={}
        material_in[material] = material_orders
        render :partial => 'material_in', :locals =>{:material_in => material_in}
      else
        render :partial => 'material_out', :locals =>{:material_out => material}
      end
    end
  end

  def create_materials_in
    status = 1
    @mat_in_list = parse_mat_in_list(params['mat_in_items'], params['mat_in_create'])
    respond_to do |format|
      format.html{
        render :pandian
      }
      format.json{
        render :json => {:status => status}
      }
    end
  end
  
  def create_materials_out
    if params['material_order'].nil?
      flash[:notice] = '请录入商品！'
      redirect_to "/stores/#{@store.id}/materials_out" and return
    end
    params['material_order'].values.each do |mo|
      mat_out_order = MatOutOrder.create(mo.merge(params[:mat_out]).merge({:store_id => @store.id}))
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

  def upload_code_matin
    code_file = params[:code_file]
    if code_file
      new_name = random_file_name(code_file.original_filename) + code_file.original_filename.split(".").reverse[0]
      FileUtils.mkdir_p Material::MAT_IN_PATH % @store.id
      file_path = Material::MAT_IN_PATH % @store.id + "/#{new_name}"
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
        @material_ins = []
        materials = Material.where(:code => @code_num.keys, :store_id => @store.id)
        @no_material_codes = (@code_num.keys - materials.map(&:code)) || []
        materials.each do |material|
          temp_material_orders = material.material_orders.not_all_in
          material_orders = get_mo(material, temp_material_orders)
          material_orders.each do |mo|
            mm ={:mo_code => mo.code, :mo_id => mo.id, :mat_code => material.code,
              :mat_name => material.name, :mat_price => material.price}
            @material_ins << mm
          end
        end if materials
      end
    end
  end

  def upload_code_matout
    code_file = params[:code_file]
    if code_file
      new_name = random_file_name(code_file.original_filename) + code_file.original_filename.split(".").reverse[0]
      FileUtils.mkdir_p Material::MAT_OUT_PATH % @store.id
      file_path = Material::MAT_OUT_PATH % @store.id + "/#{new_name}"
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
        @material_ins = []
        @material_outs = Material.where(:code => @code_num.keys, :store_id => @store_id)
      end
    end
  end

  protected

  def find_store
    @store = Store.find_by_id(params[:store_id])
  end

  def parse_mat_in_list(mat_in_items, mat_in_flag)
    mat_in_orders = []
    mat_in_items.split(",").each do |mat_in_item|
      mii = mat_in_item.split("_")
      mat_code = mii[0]
      mo_code = mii[1]
      num = mii[2]
      material = Material.find_by_code_and_status_and_store_id mat_code,Material::STATUS[:NORMAL],@store.id
      material_order = MaterialOrder.find_by_code mo_code

      mat_in_orders << {:mo_code => mo_code, :mat_code => mat_code, :num => num, :mat_unit => material.unit,
        :mat_name => material.name}
      if mat_in_flag == "1"
        mat_in_order = MatInOrder.create({:material => material, :material_order => material_order,
            :material_num => num, :price => material.price, :staff_id => cookies[:user_id]
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
    
    end unless mat_in_items.blank?
    mat_in_orders
  end
end