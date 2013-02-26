#encoding: utf-8
class ViolationRewardsController < ApplicationController

  layout "staff"

  before_filter :get_store

  def create
    ViolationReward.transaction do
      begin
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
    @violation_reward = ViolationReward.find_by_id(params[:id])
    @violation_reward.update_attributes(params[:violation_reward]) if @violation_reward
    redirect_to store_staff_path(@store, @violation_reward.staff_id)
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
  
end
