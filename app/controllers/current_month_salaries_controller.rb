#encoding: utf-8
class CurrentMonthSalariesController < ApplicationController
  layout "staff"

  before_filter :get_store

  def index
    @statistics_date = params[:statistics_date] ||= DateTime.now.strftime("%Y-%m")
    
    @staffs = @store.staffs

    respond_to do |format|
      format.html
      format.xls do
        render :xls => @staffs,
                       :columns => [ :name ],
                       :headers => %w[ 姓名 ]
      end
      #format.xls { send_data @staffs.to_xls }
    end
  end

  def show
    @statistics_date = params[:statistics_date]
    month_first_day = ((params[:statistics_date] + "01").delete "-").to_i
    month_last_day = ((params[:statistics_date] + "31").delete "-").to_i
    @staff = Staff.find_by_id(params[:id])
    @salary_details = @staff.salary_details.where("current_day >= #{month_first_day} and current_day <= #{month_last_day}")
    @salary = @staff.salaries.where("current_month = #{params[:statistics_date].delete '-'}").first
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
  
end
