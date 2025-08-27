class AddIndexesForFrequentQueries < ActiveRecord::Migration[7.1]
  def change
    add_index :track_management_sleep_records, [:user_id, :created_at], 
              name: 'index_sleep_records_on_user_id_and_created_at'
    
    add_index :track_management_sleep_records, [:user_id, :wake_at], 
              name: 'index_sleep_records_on_user_id_and_wake_at'
    
    add_index :relationship_follow_records, :follower_id,
              name: 'index_follow_records_on_follower_id'
    
    add_index :relationship_follow_records, :followed_id,
              name: 'index_follow_records_on_followed_id'
  end
end