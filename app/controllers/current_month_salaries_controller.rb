#encoding: utf-8
require 'will_paginate/array'
class CurrentMonthSalariesController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store

  def index
    @statistics_date = params[:statistics_date] ||= DateTime.now.months_ago(1).strftime("%Y-%m")
    @staffs = Staff.find_by_sql("select s.* from staffs s  where s.store_id = #{@store.id} and s.status != #{Staff::STATUS[:deleted]}")
    @current_month = Salary.select("reward_num,deduct_num,total").where(:current_month=>(@statistics_date.delete '-').to_i,
      :staff_id=>@staffs.map(&:id)).inject(Hash.new){|hash,month| hash[month.staff_id] = month;hash}
    @departs = Department.where(:id=>(@staffs.map(&:department_id)|@staffs.map(&:position)).compact.uniq).inject(Hash.new){|hash,de|hash[de.id]=de.name;hash}
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
    @staff = Staff.find_by_id(params[:id])
    @departs = Department.where(:id=>[@staff.department_id,@staff.position].compact).inject(Hash.new){|hash,de|hash[de.id]=de.name;hash}
    @salary_details = Order.where("cons_staff_id_1=#{params[:id]} or cons_staff_id_2=#{params[:id]} or front_staff_id=#{params[:id]}").
      where("date_format(created_at,'%Y-%m')='#{@statistics_date}'").select("created_at,code,front_deduct+technician_deduct total_deduct")

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
