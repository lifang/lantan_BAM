#encoding: utf-8
class StationDatasController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store

  def index
    @stations = @store.stations.valid.includes(:products).paginate(:page => params[:page] ||= 1, :per_page => Station::PerPage)
  end

  def new
    #@action = 'new'
    render :replace_form
  end

  def create
    if params[:product_ids]
      params[:station][:name].strip!
      params[:station][:code].strip!
      @product_ids = params[:product_ids].map(&:to_i)
      products = Product.where(:id => params[:product_ids])
          levels = (products.map(&:staff_level)|products.map(&:staff_level_1)).uniq.sort

          @station = Station.new(params[:station].merge({:store_id => @store.id, :status => 2,:staff_level=>levels.min,
                :staff_level1=>levels[0..(levels.length/2.0)].max   }))
      station = Station.where(:code => params[:station][:code], :store_id =>@store.id ).where("status != ?", Station::STAT[:DELETED]).first
      if station.nil?
        Station.transaction do
          
          if @station.save
            @station.products = products
            flash[:notice] = "工位创建成功"
            render :successful
          else
            @notice = "工位创建失败!"
            render :replace_form
          end
        end
      else
        @notice = "工位创建失败！ 工位编号在当前门店中已经存在"
        render :replace_form
      end
    else
      render :replace_form
    end
  end

  def edit
   # @action = 'edit'
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
    station = Station.where(:code => params[:station][:code], :store_id =>@store.id ).where("status != ?", Station::STAT[:DELETED]).first
p 111111111
p station
    if (station.nil? || station.id == @station.id) && @station.update_attributes(params[:station].merge({:staff_level=>levels.min,
            :staff_level1=>levels[0..(levels.length/2.0)].max   }))
      @station.products = products
      flash[:notice] = "工位编辑成功"
      render :successful
    else
      p 22222222222
      @notice = "工位编辑失败！工位编号在当前门店中已经存在"
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