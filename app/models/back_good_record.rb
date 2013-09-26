#encoding: utf-8
class BackGoodRecord < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :material
end
