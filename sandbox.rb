require 'fileutils'
require 'date'
require 'json'
require 'unirest'
require 'zip'
require 'csv'

#This script will
#Turn on COmmons  - Done
#turn on new UI - Done
#Create courses - Done
#upload users - Done
#upload sections - Done
#complete enrollments - Done
#create principal role - Done
#make principal the principal - Done
#upload avatars - done
#import course content to demo courses - In Progress

#================
# Change these
access_token = ''
domain = ''
env = nil
csv_file = 'Avatars/avatars.csv'
source_folder = 'CSV_Import'
archive_folder = 'Archive'
course_upload_file = 'Courses/import.csv'
#================


# Don't edit from here down unless you know what you're doing.
env ? env << "." : env
base_url = "https://#{domain}.#{env}instructure.com/api/v1"

Unirest.default_header("Authorization", "Bearer #{access_token}")


unless access_token
  "Puts what is your access token?"
  access_token = gets.chomp
end

unless domain
  "Puts what is your Canvas domain?"
  domain = gets.chomp
end



#turn on feature flags (commons and new UI)
feature1url = "#{base_url}/accounts/1/features/flags/use_new_styles?state=on"
  update = Unirest.put(feature1url)
      puts "New UI has been switched on"

feature2url = "#{base_url}/accounts/1/features/flags/lor_for_account?state=on"
  update2 = Unirest.put(feature2url)
      puts "Commons Feature flag has been flipped on"



#sis import users, courses, enrollments
test_url = "https://#{domain}.#{env}instructure.com/api/v1/accounts/self"
endpoint_url = "#{test_url}/sis_imports.json?import_type=instructure_csv"

# Make generic API call to test token, domain, and env.
test = Unirest.get(test_url, headers: { "Authorization" => "Bearer #{access_token}" })

unless test.code == 200
  raise "Error: The token, domain, or env variables are not set correctly"
end

# Methods to check if the source_folder works
unless Dir.exists?(source_folder)
  raise "Error: source_folder isn't a directory, or can't be located."
end

unless Dir.entries(source_folder).detect {|f| f.match /.*(.csv)/}
  raise "Error: There are no CSV's in the source directory"
end

unless Dir.exists?(archive_folder)
  Dir.mkdir archive_folder
  puts "Created archive folder at #{archive_folder}"
end

files_to_zip = []
Dir.foreach(source_folder) { |file| files_to_zip.push(file) }

zipfile_name = "#{source_folder}/archive.zip"
Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
  files_to_zip.each do |file|
    zipfile.add(file, "#{source_folder}/#{file}")
  end
end



#Push to the CSV API endpoint.
upload = Unirest.post(endpoint_url,
  headers: {
    "Authorization" => "Bearer #{access_token}"
  },
  parameters: {
    attachment: File.new(zipfile_name, "r")
  }
)
job = upload.body

import_status_url = "#{test_url}/sis_imports/#{job['id']}"

if job["processing_errors"]
  File.delete(zipfile_name)
  raise "An error occurred uploading this file. \n #{job}"
end

if job["processing_warnings"]
  puts "Processing Errors: #{job["processing_errors"]}"
end

puts "Successfully uploaded files"
timestamp = Time.now.to_s.gsub(/\s/, '-').gsub(/:/, '-')
FileUtils.mv(zipfile_name, "#{archive_folder}/archive-#{timestamp}.zip")
puts "Lets just wait a few min for that data to process in the background"
sleep(60)


#enroll the admin users
#create permissions
roleurl = "#{base_url}/accounts/1/roles?label=principal&permissions[become_user][explicit]=1&permissions[view_analytics][explicit]=1&permissions[manage_account_memberships][explicit]=1&permissions[manage_account_settings][explicit]=1&permissions[manage_alerts][explicit]=1&permissions[manage_courses][explicit]=1&permissions[manage_developer_keys][explicit]=1&permissions[manage_global_outcomes][explicit]=1&permissions[manage_jobs][explicit]=1&permissions[manage_role_overrides][explicit]=1&permissions[manage_storage_quotas][explicit]=1&permissions[manage_sis][explicit]=1&permissions[manage_site_settings][explicit]=1&permissions[manage_user_logins][explicit]=1&permissions[read_course_content][explicit]=1&permissions[read_course_list][explicit]=1&permissions[read_messages][explicit]=1&permissions[site_admin][explicit]=1&permissions[view_error_reports][explicit]=1&permissions[view_statistics][explicit]=1&permissions[manage_feature_flags][explicit]=1&permissions[change_course_state][explicit]=1&permissions[comment_on_others_submissions][explicit]=1&permissions[create_collaborations][explicit]=1&permissions[create_conferences][explicit]=1&permissions[manage_admin_users][explicit]=1&permissions[manage_assignments][explicit]=1&permissions[manage_calendar][explicit]=1&permissions[manage_content][explicit]=1&permissions[manage_files][explicit]=1&permissions[manage_grades][explicit]=1&permissions[manage_groups][explicit]=1&permissions[manage_interaction_alerts][explicit]=1&permissions[manage_outcomes][explicit]=1&permissions[manage_sections][explicit]=1&permissions[manage_students][explicit]=1&permissions[manage_user_notes][explicit]=1&permissions[manage_rubrics][explicit]=1&permissions[manage_wiki][explicit]=1&permissions[read_forum][explicit]=1&permissions[moderate_forum][explicit]=1&permissions[post_to_forum][explicit]=1&permissions[read_announcements][explicit]=1&permissions[read_question_banks][explicit]=1&permissions[read_reports][explicit]=1&permissions[read_roster][explicit]=1&permissions[read_sis][explicit]=1&permissions[send_messages][explicit]=1&permissions[send_messages_all][explicit]=1&permissions[view_all_grades][explicit]=1&permissions[view_group_pages][explicit]=1&permissions[become_user][enabled]=1&permissions[manage_account_memberships][enabled]=0&permissions[manage_account_settings][enabled]=0&permissions[manage_alerts][enabled]=1&permissions[manage_courses][enabled]=0&permissions[manage_developer_keys][enabled]=0&permissions[manage_global_outcomes][enabled]=0&permissions[manage_jobs][enabled]=0&permissions[manage_role_overrides][enabled]=0&permissions[manage_storage_quotas][enabled]=1&permissions[manage_sis][enabled]=0&permissions[manage_site_settings][enabled]=0&permissions[manage_user_logins][enabled]=0&permissions[read_course_content][enabled]=1&permissions[read_course_list][enabled]=1&permissions[read_messages][enabled]=1&permissions[site_admin][enabled]=0&permissions[view_error_reports][enabled]=1&permissions[view_statistics][enabled]=1&permissions[manage_feature_flags][enabled]=0&permissions[change_course_state][enabled]=1&permissions[comment_on_others_submissions][enabled]=1&permissions[create_collaborations][enabled]=1&permissions[create_conferences][enabled]=1&permissions[manage_admin_users][enabled]=0&permissions[manage_assignments][enabled]=0&permissions[manage_calendar][enabled]=1&permissions[manage_content][enabled]=0&permissions[manage_files][enabled]=0&permissions[manage_grades][enabled]=0&permissions[manage_groups][enabled]=0&permissions[manage_interaction_alerts][enabled]=0&permissions[manage_outcomes][enabled]=0&permissions[manage_sections][enabled]=0&permissions[manage_students][enabled]=0&permissions[manage_user_notes][enabled]=1&permissions[manage_rubrics][enabled]=0&permissions[manage_wiki][enabled]=0&permissions[read_forum][enabled]=1&permissions[moderate_forum][enabled]=1&permissions[post_to_forum][enabled]=1&permissions[read_announcements][enabled]=1&permissions[read_question_banks][enabled]=1&permissions[read_reports][enabled]=1&permissions[read_roster][enabled]=1&permissions[read_sis][enabled]=1&permissions[send_messages][enabled]=1&permissions[send_messages_all][enabled]=1&permissions[view_all_grades][enabled]=1&permissions[view_group_pages][enabled]=1&permissions[view_analytics][enabled]=1"
  rolepost = Unirest.post(roleurl)
    PrincipalRoleData = rolepost.body
    PrincipalRoleId = PrincipalRoleData["id"]
      puts "Principal Role has now been created, assigning the user with sis_user_id of Principal to this role"

#first we need to find the CanvasId of the Principal user
discoverPrincipalId = "#{base_url}/users/sis_user_id:principal"
  discoverPrincipalId = Unirest.get(discoverPrincipalId)
    PrincipalUserIdBody = rolepost.body
    PrincipalUserId = PrincipalUserIdBody["id"]

enrollprincipal = "#{base_url}/accounts/1/admins?user_id=#{PrincipalUserId}&role_id=#{PrincipalRoleId}&send_confirmation=false"
  EnrollthePrince = Unirest.post(enrollprincipal)
  puts "That's done, moving on to loading avatars"



#lets load avatars
unless csv_file
  "Puts where is your avatar update CSV located?"
  csv_file = gets.chomp
end

unless File.exists?(csv_file)
  raise "Error: can't locate the update CSV"
end


CSV.foreach(csv_file, {:headers => true}) do |row|
  url = "#{base_url}/users/sis_user_id:#{row['user_id_column']}.json"
  update = Unirest.put(url, parameters: { "user[avatar][url]" => row['user_image_column'] })
  if update.code == 200
    puts "User #{row['user_id_column']}'s avatar updated."
  else
    puts "User #{row['user_id_column']}'s avatar failed to update."
    puts "Moving right along."
  end
end
puts "Finished updating avatars."


#lets import course content
puts "starting the course content import process - This can take a while so go grab a coffee."

CSV.foreach(course_upload_file, {:headers => true}) do |row|
  url ="#{base_url}/courses/sis_course_id:#{row['course_id']}/content_migrations"
  import_course = Unirest.post(url, parameters: { "migration_type" => "canvas_cartridge_importer", "settings[file_url]"=> "#{row['file']}"})
  job = import_course.body

end

  puts "importing course_data for courses... please be patient. This should happen in the background, so you can happily bugger off this window. Up to you though. That is pretty much all she wrote"
