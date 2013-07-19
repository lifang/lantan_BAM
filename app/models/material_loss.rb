class MaterialLoss < ActiveRecord::Base
  belongs_to :staff
  belongs_to :material

  def self.list page,per_page,store_id,sql=[nil,nil,nil]
    MaterialLoss.where(sql[0]).where(sql[1]).where(sql[2]).where("m.status = #{Material::STATUS[:NORMAL]} and ml.store_id = #{store_id}").paginate(:select =>"ml.id, ml.loss_num, ml.store_id, m.code, m.name, m.status, m.types, m.unit, m.price, m.sale_price, s.name staff_name",
              :from => "material_losses ml",
              :joins => "inner join materials m on m.id = ml.material_id inner join staffs s on s.id = ml.staff_id",
              :order => "ml.created_at desc",
              :page => page,:per_page => per_page)

    #Material.find_by_sql("select * from materials m where m.id not in(select material_id as id from mat_out_orders where
    ##{sql[0]} and #{sql[1]} and store_id = '#{store_id}' group by material_id having #{sql[2]} order by material_id) and m.status !=#{Material::STATUS[:DELETE]} and m.store_id = '#{store_id}' and #{sql[3]};").
    #    paginate(:page => page, :per_page => per_page)
    end
end

# material.code
# material.name
# material.types
# material.unit
# material.price
# material.sale_price

# staff.name

# material_loss.id
# material_loss.loss_num