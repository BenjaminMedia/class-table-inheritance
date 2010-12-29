require 'active_record'

module InheritsMigration  

  def create_class_table(table_name, options = {})
    options[:id] ||= false if options[:inherits]
    create_table(table_name, options) do |table_defintion|
      if options[:inherits]
        association_type = Object.const_get(options[:inherits].to_s.capitalize)
        association_instance = association_type.send(:new)
        attribute_column = association_instance.column_for_attribute(association_type.primary_key)
        
        field_option = {:primary_key => true, :null => false}
        field_option[:limit] = attribute_column.limit if attribute_column.limit                
        table_defintion.column "#{options[:inherits]}_id", attribute_column.type, field_option
      end
      yield table_defintion  
    end 
  end

end

ActiveRecord::ConnectionAdapters::AbstractAdapter::send :include, InheritsMigration
