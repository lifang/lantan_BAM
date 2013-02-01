#encoding:utf-8
class MaterialsController < ApplicationController

  def index
    cookies[:current_user] = "1"
    @materails_storages = Material.paginate(:conditions => "status=#{Material::STATUS[:normal]} and store_id=#{params[:store_id]}",
                                            :per_page => 10, :page => params[:page])

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
                                      :types => params[:material][:types]})
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
    puts params[:remark],"ssss"
    @material = Material.find_by_id params[:id]
    @material.update_attribute("remark",@material.remark + params[:remark]) if @martial
    render :json => {:status => 1}.to_json
  end

  def out

  end

end