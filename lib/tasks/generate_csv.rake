require 'csv'
require 'date'
require 'tempfile'

class TooManyEntries < RuntimeError
  attr_accessor :field, :quantity

  def initialize(args = {})
    self.field = args[:field]
    self.quantity = args[:quantity]
  end
end

namespace :etd do
  desc 'output csv for date specified by RAILS_ETD_CSV_START_DATE and RAILS_ETD_CSV_END_DATE, both defaulting to the previous day'
  task :output_csv => [:environment, :ensure_dates] do
    begin
      start_date = Date.parse(ENV['RAILS_ETD_CSV_START_DATE'])
      end_date = Date.parse(ENV['RAILS_ETD_CSV_END_DATE'])
      submissions = VireoSubmission.having_applicant.where(:submission_date => start_date..(end_date + 1.day)).all
      csv = generate_csv(submissions)
      puts csv
    rescue TooManyEntries => e
      puts "#{e.field} had #{e.quantity} entries, which exceeds the programmed limit. Please contact the Vireo programming group."
    end
  end

  desc 'output csv for entire database'
  task :output_all_csv => [:environment] do
    begin
      submissions = VireoSubmission.having_applicant.all
      csv = generate_csv(submissions)
      puts csv
    rescue TooManyEntries => e
      puts "#{e.field} had #{e.quantity} entries, which exceeds the programmed limit. Please contact the Vireo programming group."
    end

  end

  desc 'generate csv report and upload to grad college share'
  task :make_and_upload_csv => [:environment, :ensure_dates] do
    start_date = Date.parse(ENV['RAILS_ETD_CSV_START_DATE'])
    end_date = Date.parse(ENV['RAILS_ETD_CSV_END_DATE'])
    submissions = VireoSubmission.having_applicant.where(:submission_date => start_date..(end_date + 1.day)).all
    csv = generate_csv(submissions)
    begin
      filename = "#{start_date}.csv"
      f = File.open(filename, 'w')
      f.puts csv
      f.close
      system("smbclient //gradfps2.ad.uillinois.edu/etd --authentication-file /services/ideals-etd/etc/smb-credentials -c 'put #{filename}'")
    ensure
      File.unlink(f)
    end
  end

  task :ensure_dates do
    ENV['RAILS_ETD_CSV_START_DATE'] ||= (Date.today- 1.day).to_s
    ENV['RAILS_ETD_CSV_END_DATE'] ||= (Date.today- 1.day).to_s
  end

end

def generate_csv(submissions)
  headers = ['UIN', 'Student Name', 'First Name', 'Last Name',
             'Degree Level', 'Degree Name', 'Degree Department', 'Department Code',
             'Program', 'Program Code', 'Discipline Code',
             'Embargo Option', 'Title',
             'Deposit Date', 'Degree Month', 'Degree Year',
             'Chair', 'Advisor',
             'CommitteeMbr', 'DirectorResearch']
  header_quantity_map = {'Chair' => 5, 'Advisor' => 4, 'DirectorResearch' => 4, 'CommitteeMbr' => 10}
  CSV.generate do |csv|
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
          raise TooManyEntries.new(:field => header, :quantity => value.length) if value.length > quantity
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