class VireoSubmission < ActiveRecord::Base
  self.table_name = 'vireosubmission'
  self.primary_key = 'submission_id'

  belongs_to :item

end