require 'active_record'
require 'inherits-migration'

class ActiveRecord::Base  
  attr_reader :reflection

  def self.acts_as_superclass

    if self.column_names.include?("subtype")
      class << self
        alias_method :find_parent, :find
      end
      def self.find(*args)
        super_classes = super
        begin
          if super_classes.kind_of? Array
            super_classes.map do |item|
              if !item.subtype.nil? && !item.subtype.blank?
                inherits_type = Object.const_get(item.subtype.to_s)
                inherits_type.send(:find, item.id)
              else
                super_classes
              end
            end
          else
            if !super_classes.subtype.nil? && !super_classes.subtype.blank?
              inherits_type = Object.const_get(super_classes.subtype.to_s)
              inherits_type.send(:find, *args)
            else
              super_classes
            end
          end
        rescue
          super_classes
        end
      end

    end  

  end

  
  def self.inherits_from(parent_class_name)
    
    set_primary_key "#{parent_class_name}_id"
    has_one parent_class_name, :foreign_key => :id, :dependent => :destroy

    before_save :bind_tables

    # Bind parent and child tables
    define_method("bind_tables") do |*args|
      parent_class = send(parent_class_name)
      parent_class.subtype = self.class.to_s if parent_class.attribute_names.include?("subtype")
      parent_class.save
      self["#{parent_class_name}_id"] = parent_class.id
      true
    end
    
    # Make a parent table
    define_method(parent_class_name) do
      if eval("#{parent_class_name}_id==nil")
         send("build_#{parent_class_name}")
      else
         eval("#{parent_class_name.capitalize}.find_parent(#{parent_class_name}_id)")
      end
    end
    
    validate :parent_valid

    # Assure parent is a valid class
    define_method("parent_valid") do
      parent_class = send(parent_class_name)
      unless valid = parent_class.valid?
        parent_class.errors.each do |attr, message|
          errors.add(attr, message)
        end
      end
      valid
    end    

    # Determine inherits from parent
    reflection = create_reflection(:has_one, parent_class_name, {}, self)
    parent_class = Object.const_get(reflection.class_name)
    inherited_columns = parent_class.column_names
    inherited_columns = inherited_columns.reject { |c| self.column_names.grep(c).length > 0 || c == "type" || c == "subtype"}
    inherited_methods = parent_class.reflections.map { |key,value| key.to_s }
    inherited_methods = inherited_methods.reject { |c| self.reflections.map {|key, value| key.to_s }.include?(c) }
    inherited_columns.delete('id') if inherited_columns.include?('id')
    inherits = inherited_columns + inherited_methods
    
    # Create proxy getters and setters
    define_method('id') { self["#{parent_class_name}_id"] }
    define_method('id=') { |new_value| self["#{parent_class_name}_id"] = new_value }
    
    inherits.each do |name|
      define_method name do
        parent_class = send(parent_class_name)
        parent_class.send(name)
    	end
  	
    	define_method "#{name}=" do |new_value|
        parent_class = send(parent_class_name)
        parent_class.send("#{name}=", new_value)
    	end
    end
  
  end
end