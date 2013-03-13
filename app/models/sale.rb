#encoding: utf-8
class Sale < ActiveRecord::Base
  has_many :sale_prod_relations
  belongs_to :store
  STATUS={:UN_RELEASE =>0,:RELEASE =>1,:DESTROY =>2} #0 未发布 1 发布 2 删除
  STATUS_NAME={0=>"未发布",1=>"已发布"}
  DISC_TYPES = {:FEE =>1,:DIS =>0} #1 优惠金额  0 优惠折扣
  DISC_TYPES_NAME = {1 => "金额优惠", 0 => "折扣"}
  DISC_TIME = {:DAY =>1,:MONTH =>2,:YEAR =>3,:WEEK =>4,:TIME =>0} #1 每日 2 每月 3 每年 4 每周 0 时间段
  DISC_TIME_NAME ={1=>"本年度每天",2=>"本年度每月",3=>"本年度每年",4=>"本年度每周" }
  SUBSIDY = { :NO=>0,:YES=>1} # 0 不补贴 1 补贴
  require 'mini_magick'

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

  #上传图片并裁剪不同比例 目前为50,100,200和原图
  #img_url 上传文件的路径 sale_id所属对象的id
  #pic_types存放文件的文件夹名称 store_id 门店编号
  def self.upload_img(img_url,sale_id,pic_types,store_id,img_code=nil)
    path="#{Rails.root}/public"
    dirs=["/#{pic_types}","/#{store_id}","/#{sale_id}"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    file=img_url.original_filename
    filename="#{dirs.join}/#{img_code}img#{sale_id}."+ file.split(".").reverse[0]
    File.open(path+filename, "wb")  {|f|  f.write(img_url.read) }
    img = MiniMagick::Image.open path+filename,"rb"
    Constant::PIC_SIZE.each do |size|
      new_file="#{dirs.join}/#{img_code}img#{sale_id}_#{size}."+ file.split(".").reverse[0]
      img.run_command("convert #{path+filename}  -resize #{size}x#{size} #{path+new_file}")
    end
    return filename
  end
end
