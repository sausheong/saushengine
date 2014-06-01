Sequel.migration do
  change do

    alter_table(:locations) do
      add_index :word_id
      add_index :position_id
    end
        
  end  
end