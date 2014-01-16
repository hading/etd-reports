class VireoSubmission < ActiveRecord::Base
  self.table_name = 'vireosubmission'
  self.primary_key = 'submission_id'

  belongs_to :item
  belongs_to :applicant, :class_name => 'EPerson'

  def is_doctoral?
    self.degree_type == 'Dissertation'
  end

end