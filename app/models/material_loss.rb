class MaterialLoss < ActiveRecord::Base
  belongs_to :staff
  belongs_to :material

  def self.list page,per_page,store_id,sql=[nil,nil,nil]
    sql[0] = sql[0].blank? ? "1 = 1" : ["code = ?",sql[0]]
    sql[1] = sql[1].blank? ? "1 = 1" : ["m.name like ?", "%#{sql[1].gsub(/[%_]/){|x| '\\' + x}}%"]
    sql[2] = (sql[2].blank? ||  sql[2] == "-1") ? "1 = 1" : ["types = ?", sql[2].to_i]

    MaterialLoss.where(sql[0]).where(sql[1]).where(sql[2]).where("m.status = #{Material::STATUS[:NORMAL]} and m.store_id = #{store_id}").paginate(:select =>"ml.id, ml.loss_num, ml.store_id, m.code, m.name, m.status, m.types, m.unit, m.price, m.sale_price, s.name staff_name",
              :from => "material_losses ml",
              :joins => "inner join materials m on ml.material_id =  m.id inner join staffs s on ml.staff_id = s.id",
              :order => "ml.created_at desc",
              :page => page,:per_page => per_page)
  end
end