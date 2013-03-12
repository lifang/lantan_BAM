#encoding: utf-8
class TrainsController < ApplicationController

  layout "staff"

  def create
    @store = Store.find_by_id(params[:store_id])
    Train.transaction do
      begin
        params[:staff][:id].each do |staff_id|
          params[:train][:certificate] = params[:train][:certificate].nil? ? 1 : 0
          train = Train.new(params[:train])
          train.train_staff_relations.new({:staff_id => staff_id, :status => 1}) #是否通过考核默认为没有，status=1
          train.save
        end
      rescue
        flash[:notice] = "新建培训失败!"
      end
    end
    redirect_to store_staffs_path(@store)
  end

  def update
    train_staff_relation = TrainStaffRelation.where("staff_id = #{params[:staff_id]} and train_id = #{params[:id]}").first
    train_staff_relation.update_attribute(:status, false) if train_staff_relation
    render :text => "success"
  end
  
end
