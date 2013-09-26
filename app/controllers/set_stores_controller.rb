#encoding: utf-8
class SetStoresController < ApplicationController
  layout "role"
  before_filter :sign?, :except => [:update]
  def edit
    @store = Store.find_by_id(params[:store_id].to_i)
    @store_city = City.find_by_id(@store.city_id) if @store.city_id
    @cities = City.where(["parent_id = ?", @store_city.parent_id]) if @store_city
    @province = City.where(["parent_id = ?", City::IS_PROVINCE])
  end

  def update
    store = Store.find_by_id(params[:id].to_i)
    update_sql = {:name => params[:store_name].strip, :address => params[:store_address].strip, :phone => params[:store_phone].strip,
                  :contact => params[:store_contact].strip, :position => params[:store_position_x]+","+params[:store_position_y],
                  :opened_at => params[:store_opened_at], :status => params[:store_status].to_i, :city_id => params[:store_city].to_i }
    if store.update_attributes(update_sql)
      if !params[:store_img].nil?
          begin
          url = Store.upload_img(params[:store_img], store.id, Constant::STORE_PICS, Constant::STORE_PICSIZE)
          store.update_attribute("img_url", url)
          rescue
            flash[:notice] = "图片上传失败!"
          end
      end
      cookies.delete(:store_name) if cookies[:store_name]
      cookies[:store_name] = {:value => store.name, :path => "/", :secure => false}
      flash[:notice] = "设置成功!"
    else
      flash[:notice] = "更新失败!"
    end
    redirect_to edit_store_set_store_path
  end

  def select_cities   #选择省份时加载下面的所有城市
    p_id = params[:p_id]
    @cities = City.where(["parent_id = ?", p_id])
  end
end