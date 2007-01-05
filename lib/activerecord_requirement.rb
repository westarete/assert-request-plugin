module ValidateRequest
  # Represents a requirement whose type is an ActiveRecord class.
  class ActiveRecordRequirement
    attr_reader :requirements, :klass

    IGNORE_COLUMNS = %w( id created_at updated_at created_on updated_on created_by updated_by )

    def initialize(klass)
      @klass = klass
      @columns = []
      @requirements = {}
      init_requirements
    end
    
    # Determine if the given requirement is an ActiveRecord model.
    def self.is_model?(requirement)
      requirement.respond_to? :ancestors and
        requirement.ancestors.detect {|a| a == ActiveRecord::Base}
    end
    
    # Return the hash representation of the requirements for this ActiveRecord
    # model.
    def to_hash
      @requirements
    end
    
    private
    
    # Determine the hash representation of requirements for this ActiveRecord
    # model.
    def init_requirements
      init_columns
      @columns.each do |c|
        # For right now, we only support integer and text.
        @requirements[c.name] = (c.type == :integer) ? :integer : :text
      end
    end
    
    # Pick out the desired content columns for this activerecord class.
    def init_columns
      @klass.columns.each do |c|
        @columns << c unless IGNORE_COLUMNS.detect {|name| name == c.name }
      end
    end

  end
end