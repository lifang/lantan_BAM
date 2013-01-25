#encoding: utf-8
class MatInOrder < ActiveRecord::Base
  belongs_to :material
  belongs_to :material_order
end
