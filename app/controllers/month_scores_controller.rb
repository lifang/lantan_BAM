#encoding: utf-8
class MonthScoresController < ApplicationController

  
  def update
    @store = Store.find_by_id(params[:store_id])
    month_score = MonthScore.find_by_id(params[:id])
    month_score.update_attributes(params[:month_score]) if month_score
    @month_scores = month_score.staff.month_scores.paginate(:page => params[:page] ||= 1, :per_page => 1)
    respond_to do |format|
      format.js
    end
  end
  
end
