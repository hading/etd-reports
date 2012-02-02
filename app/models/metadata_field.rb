class MetadataField < ActiveRecord::Base
  self.table_name = 'metadatafieldregistry'
  self.primary_key = 'metadata_field_id'

  has_many :metadata_values

end