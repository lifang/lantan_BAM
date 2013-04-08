#encoding: utf-8
class ViolationRewardsController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store

  def create
    ViolationReward.transaction do
      begin
        params[:violation_reward].delete("score_num") and params[:violation_reward].delete("salary_num") if params[:staff][:num_check] == "2"
        params[:violation_reward].delete("salary_num") if params[:staff][:num_check] == "0"
        params[:violation_reward].delete("score_num") if params[:staff][:num_check] == "1"
        params[:violation_reward][:status] = ViolationReward::STATUS[:NOMAL]
        params[:staff][:id].each do |staff_id|
          violation_reward = ViolationReward.new(params[:violation_reward])
          violation_reward.staff_id = staff_id
          violation_reward.save
        end
      rescue
        flash[:notice] = params[:violation_reward][:types] == "1" ? "新建奖励失败!" : "新建违规失败!"
      end
    end
    redirect_to store_staffs_path(@store)
  end

  def edit
    @violation_reward = ViolationReward.find_by_id(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update
    violation_reward = ViolationReward.find_by_id(params[:id])
    params[:violation_reward][:process_at] = Time.now
    violation_reward.update_attributes(params[:violation_reward]) if violation_reward

    if violation_reward.types
      @rewards = violation_reward.staff.violation_rewards.where("types = true").
                paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    else
      @violations = violation_reward.staff.violation_rewards.where("types = false").
                paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    end


    respond_to do |format|
      format.js
    end
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
  
end
