require 'csv'
require 'date'

namespace :etd do
  desc 'output csv for date specified by RAILS_ETD_CSV_START_DATE and RAILS_ETD_CSV_END_DATE, both defaulting to the previous day'
  task :output_csv => :environment do
    ENV['RAILS_ETD_CSV_START_DATE'] ||= (Date.today- 1.day).to_s
    ENV['RAILS_ETD_CSV_END_DATE'] ||= (Date.today- 1.day).to_s
    start_date = Date.parse(ENV['RAILS_ETD_CSV_START_DATE'])
    end_date = Date.parse(ENV['RAILS_ETD_CSV_END_DATE'])
    submissions = VireoSubmission.where(:submission_date => start_date..(end_date + 1.day)).all
    csv = CSV.generate do |csv|
      
      submissions.each do |s|
        data = s.item.export_data_hash
        csv << [data[:uin], data[:student_name], data[:degree_type], data[:degree_name],
                data[:degree_department], data[:embargo_option], data[:title],
                data[:deposit_date], data[:degree_date], data[:advisor_name],
                data[:committee_chair], data[:committee].join('; ')]
      end
    end
    puts csv
  end
end
