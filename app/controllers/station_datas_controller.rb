#encoding: utf-8
class StationDatasController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store

  def index
    @stations = @store.stations.valid.includes(:products).paginate(:page => params[:page] ||= 1, :per_page => Station::PerPage)
  end

  def new
    @action = 'new'
    render :replace_form
  end

  def create
    if params[:product_ids]
      @product_ids = params[:product_ids].map(&:to_i)
      Station.transaction do
        products = Product.where(:id => params[:product_ids])
        levels = (products.map(&:staff_level)|products.map(&:staff_level_1)).uniq.sort
        params[:station][:name].strip!
        params[:station][:code].strip!
        @station = Station.create(params[:station].merge({:store_id => @store.id, :status => 2,:staff_level=>levels.min,
              :staff_level1=>levels[0..(levels.length/2.0)].max   }))
        if @station.save
          @station.products = products
          flash[:notice] = "工位创建成功"
          render :successful
        else
          @notice = "工位创建失败！ #{@station.errors.messages.values.flatten.join("<br/>")}"
          render :replace_form
        end
      end
    else
      render :replace_form
    end
  end

  def edit
    @action = 'edit'
    @station = Station.includes(:products).find(params[:id])
    render :replace_form
  end

  def update
    levels =[]
    @station = Station.find(params[:id])
    if params[:product_ids]
      @product_ids = params[:product_ids].map(&:to_i)
      products = Product.where(:id => params[:product_ids])
      levels = (products.map(&:staff_level)|products.map(&:staff_level_1)).uniq.sort
    end
    params[:station][:name].strip!
    params[:station][:code].strip!
    if  @station.update_attributes(params[:station].merge({:staff_level=>levels.min,
            :staff_level1=>levels[0..(levels.length/2.0)].max   }))
      @station.products = products
      flash[:notice] = "工位编辑成功"
      render :successful
    else
      @notice = "工位编辑失败！#{@station.errors.messages.values.flatten.join("<br/>")}"
      render :replace_form
    end
  end

  def destroy
    @station = Station.find(params[:id])
    @station.status = 4
    flash[:notice] = "工位删除成功"
    redirect_to "/stores/#{@store.id}/station_datas" if @station.save
  end

  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end
end