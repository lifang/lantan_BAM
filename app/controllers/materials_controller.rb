#encoding:utf-8
class MaterialsController < ApplicationController
  respond_to :json, :xml, :html

  def index
    cookies[:current_user] = "1"
    @materails_storages = Material.normal.paginate(:conditions => "store_id=#{params[:store_id]}",
                                                   :per_page => 10, :page => params[:page])
    @out_records = MatOutOrder.out_list params[:page],10, params[:store_id]
    @in_records = MatInOrder.in_list params[:page],10, params[:store_id]

  end

  def new

  end

  def create
    @material = Material.find_by_code_and_status_and_store_id params[:barcode].strip,Material::STATUS[:normal],params[:store_id]
    @material_order = MaterialOrder.find_by_code params[:code].strip
    Material.transaction do
      begin
        if @material
          @material.update_attribute(:storage, @material.storage.to_i + params[:num].to_i)
        else
          @material = Material.create({:code => params[:barcode].strip,:name => params[:name].strip,
                                       :price => params[:price].strip, :storage => params[:num].strip,
                                       :status => Material::STATUS[:normal],:store_id => params[:store_id],
                                       :types => params[:material][:types],:check_num => params[:num].strip})
        end
        if @material_order
          MatInOrder.create({:material => @material, :@material_order => @material_order, :material_num => params[:num],
                             :price => params[:price],:staff_id => cookies[:current_user]})
        else
          MatInOrder.create({:material => @material, :material_num => params[:num],:price => params[:price],
                             :staff_id => cookies[:current_user]})
        end
      rescue

      end
    end
    redirect_to store_materials_path(params[:store_id])
  end

  def remark
    puts params[:remark],"ssss:#{params[:id]}"
    @material = Material.find_by_id(params[:id])
    @material.update_attribute(:remark,params[:remark]) if @material
    render :json => {:status => 1}.to_json
  end

  def check
    #puts params[:num],"m_id:#{params[:id]}"
    @material = Material.find_by_id(params[:id])
    @material.update_attributes(:storage => params[:num].to_i, :check_num => params[:num].to_i) if @material
    render :json => {:status => 1}.to_json
  end

  def out
    @type = 0
    @staffs = Staff.all(:select => "s.id,s.name",:from => "staffs s",
                        :conditions => "s.store_id=#{params[:store_id]} and s.status=#{Staff::STATUS[:normal]}")
  end

  def search
    str = params[:name].strip.length > 0 ? "name like '%#{params[:name]}%' and types=#{params[:types]} " : "types=#{params[:types]}"
    if params[:type].to_i == 1 && params[:from]
      if params[:from].to_i == 0
        str += " and store_id=#{Constant::STORE_ID} "
      elsif params[:from].to_i > 0
        str += " and store_id=#{params[:store_id]} "
      end
    end
    @search_materials = Material.normal.all(:conditions => str)
    puts  @search_materials.size,"------------=======-------------"
    @type = params[:type].to_i == 0 ? 0 : 1
    respond_with(@search_materials,@type) do |format|
      format.html
      format.js
    end
  end

  def out_order
    #puts params[:store_id],params[:staff],"----#{params[:selected_items]}--------"
    status = MatOutOrder.new_out_order params[:selected_items],params[:store_id],params[:staff]
    render :json => {:status => status}
  end

  def order
    @type = 1
    @use_card_count = SvcReturnRecord.store_return_count params[:store_id]
  end

  def material_order
    puts params[:store_id],params[:selected_items],params[:supplier],params[:use_count],params[:sale_id]
    status = MaterialOrder.make_order
    MaterialOrder.transaction do
      #begin
        if params[:supplier]
          #向总部订货
          if params[:supplier].to_i == 0
            #生成订单
            material_order = MaterialOrder.create({
                                                      :supplier_id => params[:supplier], :supplier_type => Supplier::TYPES[:head],
                                                      :code => MaterialOrder.material_order_code(params[:store_id].to_i), :status => MaterialOrder::STATUS[:normal],
                                                      :staff_id => cookies[:current_user],:store_id => params[:store_id]
                                                  })
            if material_order
              price = 0
              #订单相关的物料
              params[:selected_items].split(",").each do |item|
                price += item.split("_")[2].to_f * item.split("_")[1].to_i
                m = Material.normal.find_by_id item.split("_")[0]
                MatOrderItem.create({:material_order => material_order, :material => m, :material_num => item.split("_")[1],
                                     :price => item.split("_")[2].to_f})   if m

              end
              material_order.update_attribute(:price,price)
              #使用储值抵货款
              if params[:use_count].to_i > 0
                SvcReturnRecord.create({
                    :store_id => params[:store_id],:types => SvcReturnRecord::TYPES[:out],
                    :price => params[:use_count]
                                       })
              end
              #使用活动代码
            end
            #material = Material.find_by_id_and_store_id
          elsif params[:supplier].to_i > 0

          end
        end
      #rescue
      #  status = 2
      #end
    end
    render :json => {:status => status}
  end

  def get_act_count
    puts params[:code]
    sale = Sale.find_by_code params[:code]
    text = sale.nil? ? "" : sale.sub_content
    sale_id = sale.nil? ? "" : sale.id
    render :json => {:status => 1,:text => text,:sale_id => sale_id}
  end

  def add
    puts params[:store_id]
    material = Material.find_by_code params[:code]
      material =  Material.create({:code => params[:code].strip,:name => params[:name].strip,
                                 :price => params[:price].strip, :storage => params[:count].strip,
                                 :status => Material::STATUS[:normal],:store_id => params[:store_id],
                                 :types => params[:types],:check_num => params[:count].strip}) if material.nil?
    x = {:status => 1, :material => material}.to_json
    puts x
    render :json => x
  end
end