module ValidateRequest
  # Represents a requirement whose type is an ActiveRecord class.
  class ActiveRecordRequirement
    cattr_accessor :ignore_columns
    
    # The set of columns in the ActiveRecord model that we should ignore by
    # default. You could modify this in your environment.rb if its default 
    # settings don't suit your appliction. 
    @@ignore_columns = %w( id created_at updated_at created_on updated_on )

    def initialize(requirements)
      @requirements = requirements
    end

    # Recursively expand the any ActiveRecord types (and exclusions) in this
    # object's requirements, and return the result.
    def expand
      expand_requirements(@requirements)
    end
    
    # Recursively expand any ActiveRecord types (and exclusions) in the 
    # given requirements, and return the result.
    def expand_requirements(requirements)
      returning Hash.new do |expanded|
        # Extract any exclusions at this level.
        ignore = columns_to_ignore(requirements)  
        requirements.each do |key, value|  
          if value.kind_of? Hash
            # Recursively expand nested hashes.
            expanded[key] = expand_requirements(value)
          elsif is_model? value
            # Expand model requirements.
            expanded[key] = expand_model(value, ignore)
          else
            # Just copy everything else verbatim.
            expanded[key] = value
          end
        end
      end
    end
    
    # Return the hash representation of requirements for this ActiveRecord
    # model.
    def expand_model(klass, columns_to_ignore)
      returning Hash.new do |expanded|
        # Pick out the desired columns from the model.
        columns = []
        klass.columns.each do |c|
          columns << c unless columns_to_ignore.detect {|name| name == c.name }
        end
        # Convert each activerecord type into a type that we recognize.
        columns.each do |c|
          # For right now, we only support integer and text.
          expanded[c.name] = (c.type == :integer) ? :integer : :text
        end
      end
    end
    
    # Determine which columns to ignore at this level based off the params 
    # hash. Returns the complete set of columns to ignore for this level, and
    # removes any except clauses (if appropriate) from the params argument.
    def columns_to_ignore(params)
      returning @@ignore_columns do |columns|
        # Don't remove the :except clause unless there's a model to go with it.
        # Otherwise, we presume that there's actually a parameter named :except.
        if contains_model? params
          columns << params.delete(:except)
          columns.flatten!
        end
      end
    end

    # Determine if the given requirement is an ActiveRecord model.
    def is_model?(requirement)
      requirement.respond_to? :ancestors and
        requirement.ancestors.detect {|a| a == ActiveRecord::Base}
    end
    
    # Determine whether the given params contains an ActiveRecord model type.
    # It only looks at the current level, i.e. it won't detect models that
    # are nested within another hash.
    def contains_model?(params)
      params.values.detect { |p| is_model? p }
    end
        
  end
end