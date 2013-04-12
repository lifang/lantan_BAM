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
  def self.set_code(length,model_n)
    chars = (1..9).to_a + ("a".."z").to_a + ("A".."Z").to_a
    code=(1..length).inject(Array.new) {|codes| codes << chars[rand(chars.length)]}.join("")
    codes=eval(model_n.capitalize).all.map(&:id)
    if codes.index(code)
      set_code(length)
    else
      return code
    end
  end

  #上传图片并裁剪不同比例 目前为50,100,200和原图
  #img_url 上传文件的路径 sale_id所属对象的id
  #pic_types存放文件的文件夹名称 store_id 门店编号
  def self.upload_img(img_url,sale_id,pic_types,store_id,pics_size,img_code=nil)
    path = Constant::LOCAL_DIR
    dirs=["/#{pic_types}","/#{store_id}","/#{sale_id}"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    file=img_url.original_filename
    filename="#{dirs.join}/#{img_code}img#{sale_id}."+ file.split(".").reverse[0]
    File.open(path+filename, "wb")  {|f|  f.write(img_url.read) }
    img = MiniMagick::Image.open path+filename,"rb"
    pics_size.each do |size|
      new_file="#{dirs.join}/#{img_code}img#{sale_id}_#{size}."+ file.split(".").reverse[0]
      resize = size > img["width"] ? img["width"] : size
      img.run_command("convert #{path+filename}  -resize #{resize}x#{resize} #{path+new_file}")
    end
    return filename
  end
  
  #统计活动订单的数量，金额，及优惠金额
  def self.count_sale_orders(store_id)
    sql ="select count(o.id) o_num,concat_ws('--',date_format(s.started_at,'%Y.%m.%d'),date_format(s.ended_at,'%Y.%m.%d')) day,
         s.introduction intro,sum(o.price) sum,s.name,s.id from sales s  inner join orders o on s.id=o.sale_id where s.store_id=?
         group by s.id;"
    return Sale.find_by_sql([sql,store_id])
  end

  #统计活动订单的数量，金额，及优惠金额
  def self.count_sale_orders_search(store_id,started_at=nil,ended_at=nil,name=nil)
    sql ="select count(o.id) o_num,sum(o.price) sum,concat_ws('--',date_format(s.started_at,'%Y.%m.%d'),date_format(s.ended_at,'%Y.%m.%d')) day,
         s.introduction intro,s.name,s.id from sales s  inner join orders o on s.id=o.sale_id where s.store_id=#{store_id}"
    sql += " and s.ended_at>='#{started_at}'" unless started_at.nil? || started_at =="" || started_at.length==0
    sql += " and s.ended_at<='#{ended_at}'" unless ended_at.nil? || ended_at =="" || ended_at.length==0
    sql += " and s.name like '#{name}'"   unless name.nil? || name =="" || name.length==0
    sql += " group by s.id"
    return Sale.find_by_sql(sql)
  end
end
