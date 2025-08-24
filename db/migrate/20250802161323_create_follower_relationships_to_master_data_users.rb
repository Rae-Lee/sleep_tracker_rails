class CreateFollowerRelationshipsToMasterDataUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :relationship_follow_records do |t|
      t.bigint :follower_id, null: false
      t.bigint :followed_id, null: false

      t.timestamps
    end

    add_index :relationship_follow_records, %i[follower_id followed_id], unique: true
  end
end
