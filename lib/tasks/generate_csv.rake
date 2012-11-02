require 'csv'
require 'date'

class TooManyEntries < RuntimeError
end

namespace :etd do
  desc 'output csv for date specified by RAILS_ETD_CSV_START_DATE and RAILS_ETD_CSV_END_DATE, both defaulting to the previous day'
  task :output_csv => :environment do
    begin
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
                 'Chair', 'Advisor',
                 'CommitteeMbr', 'DirectorResearch']
      header_quantity_map = {'Chair' => 2, 'Advisor' => 2, 'DirectorResearch' => 2, 'CommitteeMbr' => 8}
      csv = CSV.generate do |csv|
        csv << generate_headers(headers, header_quantity_map)
        submissions.each do |s|
          data = s.item.export_data_hash
          csv << headers.collect do |header|
            field = header.downcase.gsub(' ', '_').to_sym
            value = data[field]
            if quantity = header_quantity_map[header]
              #here value will always be an array
              #Error if there are too many values
              #Add blanks if there are not enough values
              raise TooManyEntries.new("Too many entries for #{header}.") if value.length > quantity
              if value.length < quantity
                (quantity - value.length).times do
                  value << ""
                end
              end
              value
            else
              value.is_a?(Array) ? value.join('; ') : value
            end
          end.flatten
        end
      end
      puts csv
    rescue TooManyEntries
      puts "Some field had too many entries. Please consult the programming group."
    end
  end
end

def generate_headers(headers, quantity_map)
  Array.new.tap do |header_array|
    headers.each do |header|
      if quantity = quantity_map[header]
        (1..quantity).each do |index|
          header_array << "#{header}#{index}"
        end
      else
        header_array << header
      end
    end
  end
end