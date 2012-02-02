class MetadataValue < ActiveRecord::Base
  self.table_name = 'metadatavalue'
  self.primary_key = 'metadata_value_id'

  belongs_to :item
  belongs_to :metadata_field

end