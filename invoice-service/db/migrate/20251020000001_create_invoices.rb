class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.integer :customer_id, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.date :emission_date, null: false
      t.string :status, null: false, limit: 50, default: 'pending'

      t.timestamps
    end

    add_index :invoices, :customer_id
    add_index :invoices, :emission_date
    add_index :invoices, :status
  end
end
