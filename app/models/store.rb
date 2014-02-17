#encoding: utf-8
class Store < ActiveRecord::Base
  require 'mini_magick'
  has_many :stations
  has_many :reservations
  has_many :products
  has_many :sales
  has_many :work_orders
  has_many :svc_return_records
  has_many :goal_sales
  has_many :message_records
  has_many :notices
  has_many :package_cards
  has_many :staffs
  has_many :materials
  has_many :suppliers
  has_many :month_scores
  has_many :complaints
  has_many :sv_cards
  has_many :store_chain_relations
  has_many :depots
  has_many :customer_store_relations
  has_many :customers, :through => :customer_store_relations

  belongs_to :city
  has_many :roles

  AUTO_SEND = {:YES=>1,:NO=>0}  #是否自动发送 1 自动发送 0 不自动发送
  STATUS = {
    :CLOSED => 0,       #0该门店已关闭，1正常营业，2装修中, 3已删除
    :OPENED => 1,
    :DECORATED => 2,
    :DELETED => 3
  }
  S_STATUS = {
    0 => "已关闭",
    1 => "正常营业",
    2 => "装修中",
    3 => "已删除"
  }
  EDITION_LV ={       #门店使用的系统的版本等级
    0 => "实用版",
    1 => "精英版",
    2 => "豪华版",
    3 => "旗舰版"
  }
  EDITION_NAME = {:FACTUARL => 0} # 使用版  0

  CASH_AUTH = {:NO => 0, :YES => 1} #是否有在pad上收银的权限
  def self.upload_img(img_url,store_id,pic_types,pics_size,img_code=nil)
    path = Constant::LOCAL_DIR
    dirs=["/#{pic_types}","/#{store_id}"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    file=img_url.original_filename
    filename="#{dirs.join}/#{img_code}img#{store_id}."+ file.split(".").reverse[0]
    File.open(path+filename, "wb")  {|f|  f.write(img_url.read) }
    img = MiniMagick::Image.open path+filename,"rb"
    pics_size.each do |size|
      new_file="#{dirs.join}/#{img_code}img#{store_id}_#{size}."+ file.split(".").reverse[0]
      resize = size > img["width"] ? img["width"] : size
      height = img["height"].to_f*resize/img["width"].to_f > 345 ?  345 : resize
      img.run_command("convert #{path+filename}  -resize #{resize}x#{height} #{path+new_file}")
    end
    return filename
  end

end
