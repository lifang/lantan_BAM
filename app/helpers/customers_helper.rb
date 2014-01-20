module CustomersHelper
  def get_cus_car_num customer_id   #获取某个客户的所有车牌及车型
    nums = CarNum.find_by_sql(["select cn.num,cm.name mname,cb.name bname from customer_num_relations cnr
        inner join car_nums cn on cnr.car_num_id=cn.id
        left join car_models cm on cn.car_model_id=cm.id
        left join car_brands cb on cm.car_brand_id=cb.id
        where cnr.customer_id=?", customer_id])
    num_str = nums.inject([]){|a,n| a << n.num;a} if nums.any?
    brand_str = nums.inject([]){|a,n| a << "#{n.bname} #{n.mname}";a} if nums.any?
    return [num_str.nil? ? "" : num_str.join(","), brand_str.nil? ? "" : brand_str.join(",")]
  end


end
