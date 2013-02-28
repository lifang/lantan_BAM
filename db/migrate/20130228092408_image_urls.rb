class ImageUrls < ActiveRecord::Migration
  def change
    create_table :image_urls do |t|
      t.integer :product_id
      t.string  :img_url
    end
  end
end
