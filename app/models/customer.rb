#encoding: utf-8
class Customer < ActiveRecord::Base
  has_many :customer_num_relations
  has_many :c_svc_relations
  has_many :c_pcard_relations
  has_many :revisits
  has_many :send_messages
  has_many :c_svc_relations

  #客户状态
  STATUS = {:NOMAL => 0, :DELETED => 1} #0 正常  1 删除
  #客户类型
  IS_VIP = {:NORMAL => 0, :VIP => 1} #0 常态客户 1 会员卡客户
  TYPES = {:GOOD => 0, :NORMAL => 1, :STRESS => 2} #1 优质客户  2 一般客户  3 重点客户
  C_TYPES = {0 => "优质客户", 1 => "一般客户", 2 => "重点客户"}


  def self.search_customer(c_types, car_num, started_at, ended_at, name, phone, is_vip, page)
    base_sql = "select cu.id, ca.num, cu.name, cu.mobilephone, cu.is_vip from customers cu
        left join customer_num_relations cnr on cnr.customer_id = cu.id
        left join car_nums ca on ca.id = cnr.car_num_id "
    condition_sql = "where cu.status = #{STATUS[:NOMAL]} "
    params_arr = [""]
    unless c_types.nil? or c_types == "-1"
      condition_sql += " and cu.types = ? "
      params_arr << c_types.to_i
    end
    unless name.nil? or name.strip.empty?
      condition_sql += " and cu.name = ? "
      params_arr << name.strip
    end
    unless phone.nil? or phone.strip.empty?
      condition_sql += " and cu.mobilephone = ? "
      params_arr << phone.strip
    end
    unless is_vip.nil? or is_vip.strip.empty?
      condition_sql += " and cu.is_vip = ? "
      params_arr << is_vip.to_i
    end
    unless car_num.nil? or car_num.strip.empty?
      condition_sql += " and ca.num = ? "
      params_arr << car_num.strip
    end
    is_has_order = false
    unless started_at.nil? or started_at.strip.empty?
      is_has_order = true
      base_sql += " inner join orders o on o.car_num_id = ca.id "
      condition_sql += " and o.created_at >= ? "
      params_arr << started_at.strip
    end
    unless ended_at.nil? or ended_at.strip.empty?
      base_sql += " inner join orders o on o.car_num_id = ca.id " unless is_has_order
      condition_sql += " and o.created_at <= ? "
      params_arr << ended_at.strip
    end
    
    params_arr[0] = base_sql + condition_sql
    return Customer.paginate_by_sql(params_arr, :per_page => 1, :page => page)
  end

end
