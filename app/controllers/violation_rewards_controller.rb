#encoding: utf-8
class ViolationRewardsController < ApplicationController

  layout "staff"

  def create
    @store = Store.find_by_id(params[:store_id])
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
  
end
