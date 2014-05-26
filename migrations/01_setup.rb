Sequel.migration do
  change do

    create_table :pages do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at
      String :title, size: 255        
      String :url, size: 255
      String :mime_type, size: 255
      String :host, size: 255
    end
    
    create_table :words do
      primary_key :id
      String :stem, size: 255
    end
    
    create_table :locations do
      primary_key :id
      Integer :position
      
      foreign_key :word_id, :words
      foreign_key :page_id, :pages
    end
    
    create_table :logs do
      primary_key :id
      DateTime :created_at
      Text :content
      Integer :level, default: 2
    end
        
  end  
end