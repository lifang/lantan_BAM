#encoding: utf-8
class MatInOrder < ActiveRecord::Base
  belongs_to :material
  belongs_to :material_order

  def self.in_list page,per_page,store_id
    MatInOrder.paginate(:select =>"m.*,o.material_num,s.name staff_name,o.price out_price,o.created_at out_time",
                        :from => "mat_in_orders o",
                        :joins => "inner join materials m on m.id=o.material_id inner join staffs s on s.id=o.staff_id",
                        :conditions => "m.status=#{Material::STATUS[:NORMAL]} and m.store_id=#{store_id}",
                        :page => page,:per_page => per_page)
  end
end
