#encoding: utf-8
class MonthScoresController < ApplicationController

  def update
    @store = Store.find_by_id(params[:store_id])
    @month_score = MonthScore.find_by_id(params[:id])
    params[:month_score][:is_syss_update] = true
    @month_score.update_attributes(params[:month_score]) if @month_score
    redirect_to store_staff_path(@store, @month_score.staff_id)
  end
  
end
