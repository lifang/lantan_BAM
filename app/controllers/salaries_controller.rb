#encoding: utf-8
class SalariesController < ApplicationController
  before_filter :sign?

  def destroy
    @store = Store.find_by_id(params[:store_id])
    
    salary = Salary.find_by_id(params[:id])
    salary.update_attribute(:status, true) if salary
    
    @salaries = salary.staff.salaries.where("status = false").
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    respond_to do |format|
      format.js
    end
  end

  def update
    salary = Salary.where(:staff_id=>params[:id],:current_month=>(params[:current_month].delete "-").to_i).first
    staff = salary.staff
    pre_total = salary.reward_num - salary.voilate_fee + salary.work_fee + salary.manage_fee - salary.tax_fee
    total_price = params[:reward_num].to_f - params[:voilate_fee].to_f+params[:work_fee].to_f+params[:manage_fee].to_f - params[:tax_fee].to_f
    fact_fee = (salary.fact_fee + total_price-pre_total).round(1)
    total = params[:total].to_f - salary.fact_fee + fact_fee
    salary.update_attributes(:reward_num => params[:reward_num],:work_fee=>params[:work_fee],:manage_fee=>params[:manage_fee],
      :tax_fee=>params[:tax_fee],:voilate_fee => params[:voilate_fee],:fact_fee =>fact_fee) if salary
    render :json =>{:msg=>"success",:name=>staff.name,:salary =>salary,:total=>total}
  end
  
end
