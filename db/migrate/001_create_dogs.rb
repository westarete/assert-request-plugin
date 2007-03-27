class CreateDogs < ActiveRecord::Migration
  def self.up
    create_table :dogs, :force => true do |t|
      t.column :name, :string
      t.column :breed, :string
      t.column :age_in_years, :integer
      # We include these columns to make sure that they're ignored by 
      # ActiveRecord-style constraints.
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
      t.column :created_on, :date
      t.column :updated_on, :date
    end
  end
  
  def self.down
    drop_table "dogs"
  end
end
