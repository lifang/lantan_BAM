class CarBrand < ActiveRecord::Base
  belongs_to :capital
  has_many :car_models

  def self.get_brand_by_capital(capital_id)
    CarBrand.find_all_by_capital_id(capital_id).to_json
  end


  def self.load_car
    url = "http://data.auto.sina.com.cn/"
    agent = Mechanize.new
    page = agent.get(url)
    source = Hpricot(page.body)
    if source.search('div[@class=ppai clearfix]').length != 0
      source.search('div[@class=ppai clearfix]').each do |ppai|
        p ppai.search('div[@class=mod]').inner_html
      end
   
    end
  end

  
end
