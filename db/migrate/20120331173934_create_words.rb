class CreateWords < ActiveRecord::Migration
  def change
    create_table :words do |t|
      t.string :word
      t.string :code
      t.string :status
      t.timestamps
    end
    add_index :words, :word
    add_index :words, :code
    add_index :words, :status
  end
end
