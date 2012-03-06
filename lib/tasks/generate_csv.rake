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
    headers = ['UIN', 'Student Name',
               'Degree Type', 'Degree Name', 'Degree Department', 'Department Code',
               'Program', 'Program Code', 'Discipline Code',
               'Embargo Option', 'Title',
               'Deposit Date', 'Degree Month', 'Degree Year',
               'Committee Chair', 'Advisor Name',
               'Committee Members', 'Research Director']
    csv = CSV.generate do |csv|
      csv << headers
      submissions.each do |s|
        data = s.item.export_data_hash
        csv << headers.collect do |header|
          field = header.downcase.gsub(' ', '_').to_sym
          value = data[field]
          value.is_a?(Array) ? value.join('; ') : value
        end
      end
    end
    puts csv
  end
end
