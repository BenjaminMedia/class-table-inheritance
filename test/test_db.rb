
ActiveRecord::Base.connection.create_cti_table :products, :has_children => true do |t|
  t.string :title
  t.decimal :price
  t.timestamps
end

class Product < ActiveRecord::Base
  has_children 
end

ActiveRecord::Base.connection.create_cti_table :books, :has_parent => :product, :has_children => true do |t|
  t.integer :page_count
end

class Book < ActiveRecord::Base
  has_children
  has_parent :product
end

ActiveRecord::Base.connection.create_cti_table :novels, :has_parent => :book do |t|
  t.integer :chapter_count
end

class Novel < ActiveRecord::Base
  has_parent :book
end

ActiveRecord::Base.connection.create_cti_table :encyclopedias, :has_parent => :book do |t|
  t.integer :entry_count
end

class Encyclopedia < ActiveRecord::Base
  has_parent :book
end

ActiveRecord::Base.connection.create_cti_table :videos, :has_parent => :product do |t|
  t.integer :duration_in_minutes
end

class Video < ActiveRecord::Base
  has_parent :product
end
