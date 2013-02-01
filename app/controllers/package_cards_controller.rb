#encoding: utf-8
class PackageCardsController < ApplicationController
  # 营销管理 -- 套餐卡

  def index
    cards=PackageCard.paginate_by_sql("select started_at,ended_at,id from package_cards where store_id=2
         and status=#{PackageCard::STAT[:NORMAL]}", :page => params[:page], :per_page => 5)  #store_id 为硬写
    @card_hash={}
    cards.each do |card|
      @card_hash[card.id]=Product.find_by_sql("select s.name,p.product_num from products s inner join
     pcard_prod_relations p on s.id=p.product_id  where p.package_card_id=#{card.id}")
    end
  end #套餐卡列表

  def create
    parms = {:name=>params[:name],:img_url=>params[:img_url],:started_at=>params[:started_at],:ended_at=>params[:ended_at],
      :store_id=>params[:store_id],:status=>PackageCard::STAT[:NORMAL],:price=>params[:price],:created_at=>Time.now.strftime("%Y-%M-%d")
    }
    pcard=PackageCard.create(parms)
    params[:products].each do |key,value|
      PcardProdRelation.create(:package_card_id=>pcard.id,:product_id=>key,:product_num=>value)
    end
  end #添加套餐卡

  def sale_reords
    cards=PackageCard.find_by_sql("select started_at,ended_at,id from package_cards where store_id=2 and status=#{PackageCard::STAT[:NORMAL]}")
    #store_id 为硬写
    @card_hash={}
    cards.each do |card|
      unless card.c_pcard_relations.blank?
        @card_hash[card.name]= Customer.find_by_sql("select c.name,c.mobilphone,p.content from customers c inner join c_pcard_relations p
         where p.package_card_id= #{card.id} ")
      end
    end  #content中存放使用情况 将所有产品或服务以字符串组合存放，包含 产品id,name,总数和已使用数
  end #销售记录
end
