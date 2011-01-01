require 'active_record'

module ClassTableInheritanceMigration  
      
  def create_cti_table(table_name, options = {})
    options[:id] ||= false if options[:has_parent]
    create_table(table_name, options) do |table_defintion|
      if options[:has_parent]
        association_type = Object.const_get(options[:has_parent].to_s.capitalize)
        association_instance = association_type.send(:new)
        attribute_column = association_instance.column_for_attribute(association_type.primary_key)
        field_option = {:primary_key => true, :null => false}
        field_option[:limit] = attribute_column.limit if attribute_column.limit                
        table_defintion.column "#{options[:has_parent]}_id", attribute_column.type, field_option
      end
      if options[:has_children]
        table_defintion.column "child_type", "string"
        table_defintion.column "child_id", "integer"
      end
      yield table_defintion  
    end 
  end

end

ActiveRecord::ConnectionAdapters::AbstractAdapter::send :include, ClassTableInheritanceMigration
