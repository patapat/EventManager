require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
	clean_phone = phone_number.gsub(/[()-. ]/, '')
	if clean_phone.length == 11 && clean_phone[0] == '1'
		clean_phone = clean_phone[1..-1]
	elsif clean_phone.length >= 11 || clean_phone.length < 10
		clean_phone = "0000000000"
	else
		clean_phone
	end
end

def hour_of_day(hour)
	t = DateTime.strptime(hour, '%m/%d/%y %H:%M')
	t.strftime("%l%p").strip
end

def day_of_week(date)
	t = DateTime.strptime(date, '%m/%d/%y %H:%M')
	t.strftime("%A") 
end

def sorted(dict)
	Hash[dict.sort_by {|k,v| v}.reverse]
end

def legislators_by_zipcode(zipcode)
	Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
		Dir.mkdir("output") unless Dir.exists? "output"

	filename = "output/thanks_#{id}.html"

	File.open(filename, 'w') do |file|
		file.puts form_letter
	end
end

puts "EventManager Initialized!"

contents = CSV.open "../event_attendees.csv", headers: true, header_converters: :symbol
reg_log_hour = Hash.new(0)
reg_log_day = Hash.new(0)

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
	id = row[0]
	name = row[:first_name]
	reg_time = row[:regdate]	

	peak_hour = hour_of_day(row[:regdate])
	reg_log_hour[peak_hour] += 1

	peak_day = day_of_week(row[:regdate])
	reg_log_day[peak_day] += 1

	clean_phone = clean_phone_number(row[:homephone])

	zipcode = clean_zipcode(row[:zipcode])
	
	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id,form_letter)
end

peak_hour_sorted = sorted(reg_log_hour)
peak_day_sorted = sorted(reg_log_day)
puts peak_hour_sorted
puts peak_day_sorted