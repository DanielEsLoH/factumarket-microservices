class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false, limit: 255
      t.string :identification, null: false, limit: 50
      t.string :email, null: false, limit: 255
      t.string :address, null: false, limit: 500

      t.timestamps
    end

    add_index :customers, :identification, unique: true
    add_index :customers, :email, unique: true
  end
end
