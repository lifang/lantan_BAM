#encoding: utf-8
class MonthScoresController < ApplicationController

  
  def update
    @store = Store.find_by_id(params[:store_id])
    month_score = MonthScore.find_by_id(params[:id])
    month_score.update_attributes(params[:month_score]) if month_score
    @month_scores = month_score.staff.month_scores.
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    respond_to do |format|
      format.js
    end
  end

  def update_sys_score
    month_score = MonthScore.find_by_id(params[:month_score_id])
    month_score.update_attribute(:sys_score, params[:sys_score]) if month_score
    render :text => "success"
  end

  def makets_totals
    p MonthScore.sort_order(params[:store_id])
    @months =MonthScore.sort_order(params[:store_id]).inject(Hash.new){|hash,order|
      hash[order.day].nil? ? hash[order.day]={order.pay_type=>order.price} : hash[order.day].merge!(order.pay_type=>order.price);hash }
    p @months
    render :layout=>'complaint'
  end
end
