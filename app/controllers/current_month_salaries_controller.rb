#encoding: utf-8
require 'will_paginate/array'
class CurrentMonthSalariesController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store

  def index
    @statistics_date = params[:statistics_date] ||= DateTime.now.months_ago(1).strftime("%Y-%m")
    @staffs = Staff.find_by_sql("select s.* from staffs s  where s.store_id = #{@store.id} and s.status != #{Staff::STATUS[:deleted]}")
    salary = Salary.where(:current_month=>(@statistics_date.delete '-').to_i,:staff_id=>@staffs.map(&:id))
    @current_month = salary.inject(Hash.new){|hash,month| hash[month.staff_id] = month;hash}
    @total = salary.map(&:fact_fee).inject(0){|num,s|num+s}
    @departs = Department.where(:id=>(@staffs.map(&:department_id)|@staffs.map(&:position)).compact.uniq).inject(Hash.new){|hash,de|hash[de.id]=de.name;hash}
    respond_to do |format|
      format.xls {
        send_data(xls_content_for(@staffs,@current_month,@departs,@statistics_date,@total,salary),
          :type => "text/excel;charset=utf-8; header=present",
          :filename => "#{@store.name}员工#{@statistics_date}工资明细.xls")
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
      where("date_format(created_at,'%Y-%m')='#{@statistics_date}'").select("created_at,code,front_deduct f_deduct,technician_deduct t_deduct")
    @score = MonthScore.where(:store_id=>params[:store_id],:current_month=>(@statistics_date.delete "-").to_i,:staff_id=>@staff.id).first
    @salary  = Salary.where(:staff_id=>@staff.id,:current_month=>(@statistics_date.delete "-").to_i).first
  end

  private
  def get_store
    @title = "本月工资"
    @store = Store.find_by_id(params[:store_id])
  end

  def xls_content_for(objs,salary,depart,month,total_fee,sals)
    sals.update_all is_edited: 0
    xls_report = StringIO.new
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => "员工#{month}工资明细"
    sheet1.row(0).concat %w{姓名 部门 职务 底薪 提成 奖励 扣款  总额 社保 补贴 加班 考核 所得税 实付款}
    objs.each_with_index do |obj,index|
      deduct = (salary[obj.id] && salary[obj.id].deduct_num) ? salary[obj.id].deduct_num : 0
      d_reward = (salary[obj.id] && salary[obj.id].reward_num) ?  salary[obj.id].reward_num : 0
      voilate = (salary[obj.id] && salary[obj.id].voilate_fee) ?  salary[obj.id].voilate_fee : 0
      total = (salary[obj.id] && salary[obj.id].total) ? salary[obj.id].total : 0
      secure = (salary[obj.id] && salary[obj.id].secure_fee) ? salary[obj.id].secure_fee : 0
      reward = (salary[obj.id] && salary[obj.id].reward_fee) ?  salary[obj.id].reward_fee : 0
      work = (salary[obj.id] && salary[obj.id].work_fee) ?  salary[obj.id].work_fee : 0
      manage = (salary[obj.id] && salary[obj.id].manage_fee) ?  salary[obj.id].manage_fee : 0
      tax = (salary[obj.id] && salary[obj.id].tax_fee) ? salary[obj.id].tax_fee : 0
      fact = (salary[obj.id] && salary[obj.id].fact_fee) ?  salary[obj.id].fact_fee : 0
      sheet1.row(index+1).concat ["#{obj.name}","#{depart[obj.position]}", "#{depart[obj.department_id]}","#{obj.base_salary}",
        "#{deduct}","#{d_reward}","#{voilate}","#{total}","#{secure}","#{reward}","#{work}","#{manage}","#{tax}","#{fact}"]
    end
    sheet1.row(objs.length+1).concat ["支付金额总计", "#{total_fee}","领取工资人数","#{objs.length}"]
    book.write xls_report
    xls_report.string
  end
end
