require 'test_helper'
require 'pp'

class TestModel < MiniTest::Unit::TestCase

    def setup_db
      return if defined?(@@db) && @@db
      @@db = true

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
    
    def create_product
      Product.create(:title=>'GI Joe Action figure', :price=>24.99)
    end
                            
    def create_book
      Book.create(:title=>'War and Peace', :price=>8.50, :page_count=>700)
    end

    def create_novel
      Novel.create(:title=>'Neuromancer', :price=>5.00, :page_count=>250)
    end
    
    def test_create_parent
      assert_equal create_product.class.name, 'Product'
    end
    
    def test_create_child
      assert_equal create_book.class.name, 'Book'
    end

    def test_create_grand_child
      assert_equal create_novel.class.name, 'Novel'
    end
    
    def test_parent_attribute
       obj = create_book
       assert_equal obj.class.name, 'Book'
       assert_equal obj.title, 'War and Peace'
    end

    def test_grand_parent_attribute
       obj = create_novel
       assert_equal obj.class.name, 'Novel'
       assert_equal obj.title, 'Neuromancer'
    end

    def test_find_first
      create_product
      assert_equal Product.first.class.name, 'Product'
      create_book
      assert_equal Book.first.class.name, 'Book'
      create_novel
      assert_equal Novel.first.class.name, 'Novel'
    end
    
    def test_find_last
      create_product
      assert_equal Product.last.class.name, 'Product'
      create_book
      assert_equal Book.last.class.name, 'Book'
      create_novel
      assert_equal Novel.last.class.name, 'Novel'
    end
    
    def test_find_via_parent
      create_book
      create_novel
      assert_equal Product.first.class.name, 'Book'
      assert_equal Product.last.class.name, 'Novel'
      assert_equal Book.first.class.name, 'Book'
      assert_equal Book.last.class.name, 'Novel'
    end

  
  
  end
