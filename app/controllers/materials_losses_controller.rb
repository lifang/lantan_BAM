#encoding:utf-8
class MaterialsLossesController < ApplicationController
  def add
    mat_losses = params[:mat_losses]
    mat_losses.each do |key,value|
      material = Material.find(mat_losses[key][:mat_id])
      unless material.nil?
        MaterialLoss.create({:name => material.name, :code => material.code,
                             :types => material.types, :price => material.price.to_i,
                             :sale_price => material.sale_price.to_i, :loss_num =>  mat_losses[key][:mat_num].to_i,
                             :specifications => material.unit, :staff_id => params[:staff],
                             :store_id => params[:hidden_store_id]
                             })
      end
    end
    flash[:notice] = "报损成功"
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