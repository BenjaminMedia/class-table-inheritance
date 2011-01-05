require 'active_record'

class ActiveRecord::Base
  
  attr_reader :reflection
  def self.has_children
    class << self
      self.class.instance_variable_set(:@cti,true)
      alias_method :child_find_by_sql, :find_by_sql
      def find_by_sql(sql)
        objects = child_find_by_sql(sql)
        if self.class.instance_variable_get(:@cti)
          puts "cti #{self.class.instance_variable_get(:@cti)}"
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
    
    # Fetch or build a parent instance
    define_method(parent_class_name) do  
      parent_id = "#{parent_class_name}_id"
      @parent ||= send("build_#{parent_class_name}") unless eval(parent_id)
      if !@parent
        eval("#{parent_class_name.capitalize}.cti=false")     
        @parent ||= eval("#{parent_class_name.capitalize}.find(#{parent_id})")     
        eval("#{parent_class_name.capitalize}.cti=true")
      end  
      @parent
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

    # Determine and save parent class
    reflection = create_reflection(:has_one, parent_class_name, {}, self)
    parent_class = Object.const_get(reflection.class_name)
    self.instance_variable_set(:@parent_class,parent_class) 

    # Determine inherits from parent
    columns = parent_class.column_names.reject { |c| self.column_names.grep(c).length > 0 || c == "child_type"}
    methods = parent_class.reflections.map { |key,value| key.to_s }
    methods = methods.reject { |c| self.reflections.map {|key, value| key.to_s }.include?(c) }
    inherits = columns + methods
    inherits.delete('id')
    inherits.delete('parent')
        
    inherits.each do |name|
      define_method name do
        parent.send(name)
      end	
    	define_method "#{name}=" do |new_value|
        parent.send("#{name}=", new_value)
    	end
    end

    # Inherit constants
    constants = parent_class.constants.reject { |c| self.constants.grep(c).length > 0}
    constants.each do |name|
      const_set(name,parent_class.const_get(name))
    end
    
    class << self
      alias_method :child_find, :find
      def find(*args)
        begin
          child_find(*args)
        rescue
          @parent_class.find(*args) if @parent_class
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
        @table = klass.arel_table
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
        @table = klass.arel_table
      end
      child_last(*args)
    end
  end

  # alias_method :child_to_a, :to_a
  # def to_a
  #   begin
  #     child_to_a
  #   rescue
  #     klass = @klass.instance_variable_get(:@parent_class)
  #     if klass
  #       @klass = klass
  #       @table = klass.arel_table
  #     end
  #     child_to_a
  #   end
  # end
  # 

  alias_method :child_find, :find
  def find(*args)
    begin
      child_find(*args)
    rescue
      klass = @klass.instance_variable_get(:@parent_class)
      if klass
        @klass = klass
        @table = klass.arel_table
      end
      child_find(*args)
    end
  end
  
end    

