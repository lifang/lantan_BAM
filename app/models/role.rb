#encoding: utf-8
class Role < ActiveRecord::Base
  has_many :staff_role_relations
  has_many :staffs, :through => :staff_role_relations, :foreign_key => "staff_id"
  has_many :role_model_relations
  has_many :role_menu_relations
  has_many :menus, :through => :role_menu_relations, :foreign_key => "menu_id"
end
