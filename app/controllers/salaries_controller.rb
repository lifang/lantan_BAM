#encoding: utf-8
class SalariesController < ApplicationController

  def destroy
    @store = Store.find_by_id(params[:store_id])
    
    salary = Salary.find_by_id(params[:id])
    salary.update_attribute(:status, true) if salary
    
    @salaries = salary.staff.salaries.where("status = false").
                paginate(:page => params[:page] ||= 1, :per_page => 1)
    respond_to do |format|
      format.js
    end
  end
  
end
