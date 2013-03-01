#encoding: utf-8
class CurrentMonthSalariesController < ApplicationController
  layout "staff"

  before_filter :get_store

  def index
    @current_month = params[:current_month] ||= Time.now.strftime("%Y-%m")
    @staffs = @store.staffs

    respond_to do |format|
      format.html
      format.xls do
        render :xls => @staffs,
                       :columns => [ :name ],
                       :headers => %w[ Name ]
      end
      #format.xls { send_data @staffs.to_xls }
    end
  end

  def show
    @staff = Staff.find_by_id(params[:id])
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
  
end
