require 'active_record'

class ActiveRecord::Base
  
  def self.has_children
    #puts "#{self.name} has children"
    class << self

      self.class.instance_variable_set(:@cti,true)

      alias_method :child_find_by_sql, :find_by_sql
      def find_by_sql(sql)
        objects = child_find_by_sql(sql)
        if self.class.instance_variable_get(:@cti)
          objects.collect! do |obj|
            if obj.child_type
              child_class = Object.const_get(obj.child_type)
              obj = child_class.find(obj.child_id)
            end
            obj
          end
        end  
        objects
      end
  
      def cti
        self.class.instance_variable_get(:@cti)
      end

      def cti=(value)
        self.class.instance_variable_set(:@cti,value)
      end

    end
  end

  
  def self.has_parent(parent_class_name)

    has_one parent_class_name, :as => :child

    set_primary_key "#{parent_class_name}_id"

    #puts "#{self.name} has a parent: #{parent_class_name}"
    
    # Fetch or build a parent instance
    define_method(parent_class_name) do  
      if !@parent 
        parent_id = send("#{parent_class_name}_id")
        if parent_id
          model_name = eval(parent_class_name.to_s.capitalize)
          model_name.cti = false     
          @parent = model_name.find(parent_id)     
          model_name.cti = true     
        end
      end  
      @parent ||= send("build_#{parent_class_name}")
    end

    define_method('parent') do
      send(parent_class_name)
    end

    before_save :save_parent

    define_method("save_parent") do 
      parent.save
      self["#{parent_class_name}_id"] = parent.id
      true
    end  
    
    validate :parent_valid

    # Assure parent is a valid class
    define_method("parent_valid") do
      unless valid = parent.valid?
        parent.errors.each do |attr, message|
          errors.add(attr, message)
        end
      end
      valid
    end
    
    after_destroy :destroy_parent
    
    define_method("destroy_parent") do
      parent.destroy
      true
    end

    # Determine and save parent class
    parent_class = Object.const_get(parent_class_name.to_s.capitalize)
    self.instance_variable_set(:@parent_class,parent_class) 

    #puts "#{self.name} inherited data from #{parent_class_name}"    
    begin
      columns = parent_class.column_names.reject { |c| self.column_names.include?(c) }
      ['id', 'child_type', 'child_id'].each { |c| columns.delete(c) }
    rescue
      columns = []
    end
    columns.each do |name|
      #puts "--#{name}"
      define_method name do
        parent.send(name)
      end	
    	define_method "#{name}=" do |new_value|
        parent.send("#{name}=", new_value)
    	end
    end

    #puts "#{self.name} inherited methods from #{parent_class_name}"    
    methods = parent_class.public_instance_methods.reject { |m| self.public_instance_methods.include?(m) }
    methods.reject! { |name| name=~/^_/ }
    methods.each do |name|
      #puts "--#{name}"
      define_method name do |*args|
        #puts "forwarding method call #{name}" 
        parent.send(name,*args)
      end	
    end

    #puts "#{self.name} inherited constants from #{parent_class_name}"    
    constants = parent_class.constants.reject { |c| self.constants.include?(c)}
    constants.each do |name|
      #puts "--#{name}"
      const_set(name,parent_class.const_get(name))
    end
    
    class << self
      alias_method :child_find, :find
      def find(*args)
        begin
          child_find(*args)
        rescue
          if @parent_class
            @parent_class.cti = false     
            @parent_class.find(*args)
            @parent_class.cti = true     
          end
        end
      end
    end
    
  end
  
end


class ActiveRecord::Relation

  alias_method :child_first, :first
  def first(*args)
    begin
      child_first(*args)
    rescue
      klass = @klass.instance_variable_get(:@parent_class)
      if klass
        @klass = klass
        @arel_table = @table = klass.arel_table 
        @arel_engine = klass.arel_engine
        @table_name = klass.table_name
      end
      child_first(*args)
    end
  end
  
  alias_method :child_last, :last
  def last(*args)
    begin
      child_last(*args)
    rescue
      klass = @klass.instance_variable_get(:@parent_class)
      if klass
        @klass = klass
        @arel_table = @table = klass.arel_table 
        @arel_engine = klass.arel_engine
        @table_name = klass.table_name
      end
      child_last(*args)
    end
  end

  alias_method :child_find, :find
  def find(*args)
    begin
      child_find(*args)
    rescue
      klass = @klass.instance_variable_get(:@parent_class)
      if klass
        @klass = klass
        @arel_table = @table = klass.arel_table 
        @arel_engine = klass.arel_engine
        @table_name = klass.table_name
      end
      child_find(*args)
    end
  end
  
end    

