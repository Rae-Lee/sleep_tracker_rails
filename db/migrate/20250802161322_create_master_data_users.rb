class CreateMasterDataUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :master_data_users do |t|
      t.string :name

      t.timestamps
    end
  end
end
