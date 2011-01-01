require 'active_record'
require 'inherits-migration'

class ActiveRecord::Base  
  attr_reader :reflection

  def self.acts_as_superclass
    if self.column_names.include?("child_type")

      class << self
        alias_method :find_parent, :find
      end 
      def self.find(*args)
        objects = find_parent(*args)
        objects = [objects] if !objects.kind_of? Array 
        objects.map! do |obj|
          child_class = Object.const_get(obj.child_type)
          child_class.find(*args)
        end
        objects.size>1 ? objects : objects.pop
      end
    end  
  end

  
  def self.inherits_from(parent_class_name)
  
    has_one parent_class_name, :as => :child

    set_primary_key "#{parent_class_name}_id"
    
    # Fetch or build a parent instance
    define_method(parent_class_name) do  
      parent_id = "#{parent_class_name}_id"
      @parent ||= send("build_#{parent_class_name}") unless eval(parent_id)
      @parent ||= eval("#{parent_class_name.capitalize}.find_parent(#{parent_id})")     
    end

    define_method('parent') do
      send(parent_class_name)
    end

    before_save :save_parent

    define_method("save_parent") do |*args|
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

    # Determine inherits from parent
    reflection = create_reflection(:has_one, parent_class_name, {}, self)
    parent_class = Object.const_get(reflection.class_name)
    columns = parent_class.column_names
    columns = columns.reject { |c| self.column_names.grep(c).length > 0 || c == "child_type"}
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

  end
end