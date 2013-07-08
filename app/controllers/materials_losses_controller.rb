#encoding:utf-8
class MaterialsLossesController < ApplicationController
   def add
     #p cookies[:user_id]
     # puts params[:store_id]
     p params[:id]
    if params[:id].empty?
      material =  MaterialLoss.new({:name => params[:name].strip, :code => params[:code].strip,
      :types => params[:types].strip, :price => params[:price].strip.to_i,
      :sale_price => params[:sale_price].strip.to_i, :loss_num => params[:loss_num].strip.to_i,
      :specifications => params[:specifications].strip, :staff_id => params[:report_person],
      :store_id => params[:store_id]
        }) if material.nil?

      if material.save
       redirect_to "/stores/#{params[:store_id]}/materials"
      end
    else
      material = MaterialLoss.find(params[:id])
     if material.update_attributes({:name => params[:name].strip, :code => params[:code].strip,
                                      :types => params[:types].strip, :price => params[:price].strip.to_i,
                                      :sale_price => params[:sale_price].strip.to_i, :loss_num => params[:loss_num].strip.to_i,
                                      :specifications => params[:specifications].strip, :staff_id => params[:report_person],
                                     })
       redirect_to "/stores/#{params[:store_id]}/materials"
     end
    end
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