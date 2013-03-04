#encoding: utf-8
class Sale < ActiveRecord::Base
  has_many :sale_prod_relations
  belongs_to :store
  STATUS={:UN_RELEASE =>0,:RELEASE =>1,:DESTROY =>2} #0 未发布 1 发布 2 删除
  STATUS_NAME={0=>"未发布",1=>"已发布"}
  DISC_TYPES = {:FEE =>1,:DIS =>0} #1 优惠金额  0 优惠折扣
  DISC_TYPES_NAME = {1 => "金额优惠", 0 => "折扣"}
  DISC_TIME = {:DAY=>1,:MONTH=>2,:YEAR=>3,:WEEK=>4,:TIME=>0} #1 每日 2 每月 3 每年 4 每周 0 时间段
  DISC_TIME_NAME ={1=>"每天",2=>"每月",3=>"每年",4=>"每周" }
  SUBSIDY = { :NO=>0,:YES=>1} # 0 不补贴 1 补贴


  #生成code
  def self.set_code(length)
    chars = (1..9).to_a + ("a".."z").to_a + ("A".."Z").to_a
    code=(1..length).inject(Array.new) {|codes| codes << chars[rand(chars.length)]}.join("")
    file = File.open(Constant::CODE_PATH,"a+")
    codes=file.read
    if codes.index(code)
      set_code(length)
    else
      file.write("#{code}\r\n")
      file.close
      return code
    end

  end

  def self.upload_img(img_url,sale_id)
    file=img_url.original_filename
    filename="/upload_images/#{file.split(".")[0]}_#{sale_id}."+ file.split(".").reverse[0]
    File.open("#{Rails.root}/public/#{filename}", "wb") do |f|
      f.write(img_url.read)
    end
    return filename
  end
end
