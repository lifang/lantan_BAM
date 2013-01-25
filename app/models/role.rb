#encoding: utf-8
class Role < ActiveRecord::Base
  has_many :staff_role_relations
  has_many :role_model_relations
  has_many :role_menu_relations
end
