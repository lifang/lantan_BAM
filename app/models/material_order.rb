#encoding: utf-8
class MaterialOrder < ActiveRecord::Base
  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many  :m_order_types
  belongs_to :supplier

  STATUS = {:pay_and_send => 0, :pay_not_send => 1, :send_not_pay => 2, :no_send_no_pay => 3, :cancel => 4}
  PAY_TYPES = {:CHARGE => 1,:LICENSE=>2, :CASH => 3, :STORE_CARD => 4 }
  PAY_TYPE_NAME = {1 => "订货付费",2=>"授权码", 3 => "现金", 4 => "门店账户扣款"}

  def self.make_order
    status = 0

    status
  end

  def self.material_order_code store_id
    store = store_id.to_s
    if store_id < 10
      store =   "00" + store_id.to_s
    elsif store_id < 100
      store =    "0" + store_id.to_s
    end
    store + Time.now.strftime("%Y%m%d%H%M%S")
  end

  def self.supplier_order_records page, per_page, store_id
    self.paginate(:select => "mo.*", :from => "material_orders mo", :conditions => "mo.supplier_id != 0",
    :page => page, :per_page => per_page)
  end

  def self.head_order_records page, per_page, store_id
    self.paginate(:select => "mo.*", :from => "material_orders mo", :conditions => "mo.supplier_id = 0",
                  :page => page, :per_page => per_page)
  end

  def self.search_orders store_id,from_date, to_date, status, supplier_id,page,per_page
    str = "mo.store_id = #{store_id} "
    if supplier_id == 0
      str += " and mo.supplier_id = 0 "
    else
      str += " and mo.supplier_id != 0 "
    end
    if status
      if status == 0
        str += " and (mo.status=#{STATUS[:send_not_pay]} or mo.status=#{STATUS[:no_send_no_pay]}) "
      elsif status == 1
        str += " and (mo.status=#{STATUS[:pay_and_send]} or mo.status=#{STATUS[:pay_not_send]}) "
      elsif status == 2
        str += " and (mo.status=#{STATUS[:no_send_no_pay]} or mo.status=#{STATUS[:pay_not_send]}) "
      elsif status == 3
        str += " and (mo.status=#{STATUS[:send_not_pay]} or mo.status=#{STATUS[:pay_and_send]}) "
      end
    end
    if from_date && from_date.length > 0
      str += " and unix_timestamp(date_format(mo.created_at,'%Y-%m-%d')) >= unix_timestamp(date_format('#{from_date}','%Y-%m-%d')) "
    end
    if to_date && to_date.length > 0
      str += " and unix_timestamp(date_format(mo.created_at,'%Y-%m-%d')) <= unix_timestamp(date_format('#{to_date}','%Y-%m-%d')) "
    end
    orders = self.paginate(:select => "mo.*", :from => "material_orders mo", :conditions => str,
                           :order => "created_at desc",
                           :page => page, :per_page => per_page)
    orders
  end
end
