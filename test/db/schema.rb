# Schema for the test database.
ActiveRecord::Schema.define(:version => 1) do
  create_table :dogs, :force => true do |t|
    t.column :name, :string
    t.column :breed, :string
    t.column :age_in_years, :integer
  end
end
