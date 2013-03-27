#encoding: utf-8
class SvcReturnRecord < ActiveRecord::Base
  belongs_to :store

  TYPES = {:in => 0, :out => 1} #门店订货为支出=1   客户消费为收入=0

  def self.store_return_count store_id
    record = self.first(:conditions => "store_id=#{store_id}",:order => "created_at desc")
    price = record.nil? ? 0 : record.total_price
  end
end
