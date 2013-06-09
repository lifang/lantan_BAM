#encoding: utf-8
class SvCard < ActiveRecord::Base
  has_many :svcard_prod_relations
  has_many :c_svc_relations
  belongs_to :store
  FAVOR = {:SAVE =>1,:DISCOUNT=>0} #1 储值卡 0 打折卡
  S_FAVOR = {1 => "储值卡", 0 => "打折卡"}
  USE_RANGE = [:ALL => 1, :CHAIN_STORE => 2, :LOCAL => 3]  #优惠卡使用范围 1全部，2仅连锁店， 3仅本店
  S_USE_RNGE = {1 => "全部", 2 => "仅连锁店", 3 => "仅本店"}
  PER_PAGE = 10

  #上传图片并裁剪不同比例 目前为50,100,200和原图
  #img_url 上传文件的路径 sale_id所属对象的id
  #pic_types存放文件的文件夹名称 store_id 门店编号
  def self.upload_img(img_url,sv_card_id,pic_types,store_id,pics_size,img_code=nil)
    path = Constant::LOCAL_DIR
    dirs=["/#{pic_types}","/#{store_id}","/#{sv_card_id}"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    file=img_url.original_filename
    filename="#{dirs.join}/#{img_code}img#{sv_card_id}."+ file.split(".").reverse[0]
    File.open(path+filename, "wb")  {|f|  f.write(img_url.read) }
    img = MiniMagick::Image.open path+filename,"rb"
    pics_size.each do |size|
      new_file="#{dirs.join}/#{img_code}img#{sv_card_id}_#{size}."+ file.split(".").reverse[0]
      resize = size > img["width"] ? img["width"] : size
      img.run_command("convert #{path+filename}  -resize #{resize}x#{resize} #{path+new_file}")
    end
    return filename
  end
end
