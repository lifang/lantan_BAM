#encoding: utf-8
class TrainsController < ApplicationController

  layout "staff"

  def create
    @store = Store.find_by_id(params[:store_id])
    Train.transaction do
      begin
        params[:staff][:id].each do |staff_id|
          train = Train.new(params[:train])
          train.train_staff_relations.new({:staff_id => staff_id, :status => 1})
          train.save
        end
      rescue
        flash[:notice] = "新建培训失败!"
      end
    end
    redirect_to store_staffs_path(@store)
  end
  
end
