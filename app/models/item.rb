class Item < ActiveRecord::Base
  self.table_name = 'item'
  self.primary_key = 'item_id'

  has_one :vireo_submission
  has_many :metadata_values

  delegate :is_doctoral?, :to => :vireo_submission

  def metadata_triples
    self.metadata_values.collect do |value|
      MetadataTriple.new.tap do |triple|
        triple.value = value.text_value
        triple.element = value.metadata_field.element
        triple.qualifier = value.metadata_field.qualifier
      end
    end
  end

  def export_data_hash
    finder = value_finder(self.metadata_triples)
    submission = self.vireo_submission
    Hash.new.tap do |h|
      h[:uin] = submission.uin || 'unknown'
      h[:student_name] = finder.call('creator')
      h[:first_name] = submission.applicant.firstname || ""
      h[:last_name] = submission.applicant.lastname || ""
      h[:degree_type] = submission.degree_type || 'unknown'
      h[:degree_level] = finder.call('degree', 'level')
      h[:degree_name] = finder.call('degree', 'name')
      h[:degree_department] = finder.call('degree', 'department')
      h[:embargo_option] = submission.embargo_description || ""
      h[:title] = finder.call('title')
      h[:deposit_date] = submission.submission_date.strftime('%F') || ""
      h[:degree_date] = finder.call('date', 'submitted')
      h[:degree_month], h[:degree_year] = h[:degree_date].split
      h[:program] = finder.call('degree', 'program')
      h[:program_code] = finder.call('degree', 'programCode')
      h[:discipline_code] = finder.call('degree', 'disciplineCode')
      h[:department_code] = finder.call('degree', 'departmentCode')
      if self.is_doctoral?
        add_doctoral_committee_fields(h, finder)
      else
        add_masters_committee_fields(h, finder)
      end
    end
  end

  def add_doctoral_committee_fields(h, finder)
    h[:advisor] = []
    h[:chair] = finder.call('contributor', 'committeeChair', true)
    h[:committeembr] = finder.call('contributor', 'committeeMember', true)
    h[:directorresearch] = finder.call('contributor', 'advisor', true)
  end

  def add_masters_committee_fields(h, finder)
    h[:advisor] = finder.call('contributor', 'advisor', true)
    h[:chair] = finder.call('contributor', 'committeeChair', true)
    h[:committeembr] = []
    h[:directorresearch] = []
  end

  protected

  #return a lambda. Calling with just element and qualifier returns the first match.
  #Calling with anything in the third argument position returns an array with all matches
  def value_finder(triples)
    lambda do |element, qualifier = nil, multiple_values = nil|
      values = triples.select { |t| t.element == element and t.qualifier == qualifier }.collect { |t| t.value }
      return multiple_values ? values : (values.first || '')
    end
  end
end