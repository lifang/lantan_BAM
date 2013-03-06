class ImageUrls < ActiveRecord::Migration
  def change
    create_table :image_urls do |t|
      t.integer :product_id
      t.string  :img_url
    end

    add_index :image_urls, :product_id
  end
end
