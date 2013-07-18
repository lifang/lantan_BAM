#encoding:utf-8
class MaterialsLossesController < ApplicationController
  def add
    mat_losses = params[:mat_losses]
    unless mat_losses.nil?
      mat_losses.each do |key,value|
        material = Material.find(mat_losses[key][:mat_id])
        if material
          MaterialLoss.create({:loss_num =>  mat_losses[key][:mat_num].to_i,
                               :material_id => material.id,
                               :staff_id => params[:staff],
                               :store_id => params[:hidden_store_id]
                               })
        end
      end
    end
    redirect_to "/stores/#{params[:hidden_store_id]}/materials"
  end

   def delete
     material =  MaterialLoss.find(params[:materials_loss_id].to_i)
     if material.destroy
        redirect_to "/stores/#{params[:store_id]}/materials"
     end
   end

   def view
     material =  MaterialLoss.find(params[:materials_loss_id].to_i)
     render :json => material
   end
end