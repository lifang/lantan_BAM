#encoding: utf-8
require 'will_paginate/array'
class CurrentMonthSalariesController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store

  def index
    @statistics_date = params[:statistics_date] ||= DateTime.now.months_ago(1).strftime("%Y-%m")
    @staffs = Staff.find_by_sql("select s.*,sa.reward_num reward_num,sa.deduct_num deduct_num,sa.total total,sa.id s_id from staffs s left join salaries sa on s.id=sa.staff_id where s.store_id = #{@store.id} and s.status != #{Staff::STATUS[:deleted]} and sa.current_month = #{(@statistics_date.delete '-').to_i}")
    respond_to do |format|
      format.xls {
        send_data(xls_content_for(@staffs),
                  :type => "text/excel;charset=utf-8; header=present",
                  :filename => "Current_Month_Salary_#{@statistics_date}.xls")
      }
      format.html{
        @staffs = @staffs.paginate(:per_page => Constant::PER_PAGE, :page => params[:page] ||= 1)
      }
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
    @title = "本月工资"
    @store = Store.find_by_id(params[:store_id])
  end

  def xls_content_for(objs)
    xls_report = StringIO.new
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => "Users"
    sheet1.row(0).concat %w{姓名 职务 底薪 提成金额 扣款金额 总额}
    count_row = 1
    objs.each do |obj|
      sheet1[count_row,0] = obj.name
      sheet1[count_row,1] = Staff::N_COMPANY[obj.type_of_w]
      sheet1[count_row,2] = obj.base_salary
      #salary = obj.salaries.where("current_month = #{(current_month.delete '-').to_i}").first
      sheet1[count_row,3] = obj.reward_num
      sheet1[count_row,4] = obj.deduct_num
      sheet1[count_row,5] = obj.total
     count_row += 1
    end
    book.write xls_report
    xls_report.string
  end
end
