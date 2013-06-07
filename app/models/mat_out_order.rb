#encoding: utf-8
class MatOutOrder < ActiveRecord::Base
  belongs_to :material
  belongs_to :material_order

  TYPES = {0 => "消耗", 1 => "调拨", 2 => "赠送", 3 => "销售"}

  def self.out_list page,per_page, store_id,sql = [nil,nil,nil]
    MatOutOrder.where(sql[0]).where(sql[1]).where(sql[2]).where("materials.status=#{Material::STATUS[:NORMAL]} and materials.store_id=#{store_id}")
    .paginate(:select =>"materials.*,o.material_num,s.name staff_name,o.price out_price,o.created_at out_time, o.types out_types",
                         :from => "mat_out_orders o",
                         :joins => "inner join materials on materials.id=o.material_id inner join staffs s on s.id=o.staff_id",
                         :order => "o.created_at desc",
                         :page => page,:per_page => per_page)
  end

  def self.new_out_order selected_items,store_id,staff,types
    status = 0
    Material.transaction do
      begin
        (selected_items.split(",") || []).each do |item|
          material = Material.find_by_id_and_store_id item.split("_")[0],store_id
          if material
            #出库记录 门店出库没有订单id和价格，并修改库存量
            MatOutOrder.create(:material => material, :material_num => item.split("_")[1],:staff_id => staff, :price => material.price, :types => types)
            material.update_attribute(:storage, material.storage - item.split("_")[1].to_i)
          end
        end
      rescue
        status = 1
      end
    end
    status
  end
end
