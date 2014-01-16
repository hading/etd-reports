require 'EPerson'
class VireoSubmission < ActiveRecord::Base
  self.table_name = 'vireosubmission'
  self.primary_key = 'submission_id'

  belongs_to :item
  belongs_to :applicant, :class_name => 'EPerson'

  def self.having_applicant
    where('applicant_id is not null')
  end

  def is_doctoral?
    self.degree_type == 'Dissertation'
  end

  def applicant_firstname
    self.applicant.firstname
  end

  def applicant_lastname
    self.applicant.lastname
  end

  def canonical_embargo_description
    case self.embargo_description
      when nil, "Open Access (OA) immediately."
        "Open"
      when "U of Illinois only (OA after 2 yrs)"
        "Campus"
      when "Closed Access (OA after 2 yrs)"
        "Close"
      else
        raise RuntimeError("Unexpected embargo type!")
    end
  end

end

