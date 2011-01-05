require 'test_helper'
require 'pp'

class TestModel < MiniTest::Unit::TestCase

    def setup_db
      return if defined?(@@db) && @@db
      @@db = true

      puts "DB Setup"
      db_name = 'test/test.db'
      system("rm -f #{db_name}")
      SQLite3::Database.new(db_name)
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => db_name)
      require 'test_db'
    end
    
    def setup
      setup_db  
    end

    def teardown
      ActiveRecord::Base.send(:descendants).each do |klass|
        klass.delete_all
      end
    end
    
    def test_create_parent
      pp obj = Product.create(:title=>'GI Joe Action figure',
                           :price=>24.99)
      assert_equal obj.class.name, 'Product'
    end

    def test_create_child
      pp obj = Book.create(:title=>'War and Peace',
                        :price=>8.50,
                        :page_count=>700)
      assert_equal obj.class.name, 'Book'
    end

    def test_create_grandchild
      pp obj = Novel.create(:title=>'Neuromancer',
                        :price=>5.25,
                        :page_count=>250)
      assert_equal obj.class.name, 'Novel'
    end

  
  
  end
