require 'rubygems'
require 'mechanize'
require 'highline/import'
require 'postageapp'
require 'json'
require 'daemons'
begin
  require './config.rb'
rescue LoadError
  puts "Couldn't find your config file."
  if File.exist? "config.example.rb"
    puts "  Looks like you forgot to rename \"config.example.rb\""
    puts "  to \"config.rb\" and fill it with your own values!"
  end
  exit 1
end

exit 0 if Time.now >= END_DATE or Time.now.hour < CLOSED_BEFORE

PostageApp.configure do |config|
  config.api_key = POSTAGEAPP_API_KEY
end

JOB_ID_INDEX = 0
JOB_TITLE_INDEX = 1
EMPLOYER_INDEX = 2
JOB_STATUS_INDEX = 5
STATUS_INDEX = 6

MAX_APPLICATIONS = 50

WORKING_DIR = File.expand_path File.dirname __FILE__

def run
  Dir.chdir WORKING_DIR
  puts "Checking Jobmine at #{Time.now}"
  username = USERNAME
  password = File.open(PWD_FILE).read.strip

  agent = Mechanize.new

  puts "Fetching Jobmine login page..."
  page = agent.get('https://jobmine.ccol.uwaterloo.ca/psp/SS/?cmd=login')
  login_form = page.form('login')

  username = ask("Your username?: ") unless username
  password = ask("#{username}'s password: ") { |q| q.echo = false } unless password
  login_form.userid = username
  login_form.pwd = password

  puts "Logging in..."
  landing_page = agent.submit(login_form, login_form.buttons.first)

  if landing_page.uri.to_s.include? "errorCode=105"
      raise "Could not log in due to invalid username or password."
  end

  puts "Fetching applications..."
  applications_link = agent.page.link_with(:text => "Applications")
  inquiry_link = agent.page.link_with(:text => "Job Inquiry")
  #interviews_link = agent.page.link_with(:text => "Interviews")
  #rankings_link = agent.page.link_with(:text => "Rankings")
  applications_page = applications_link.click.iframe('TargetContent').click
  inquiry_page = inquiry_link.click.iframe('TargetContent').click

  puts "Parsing applications..."
  new_applications = {}
  active_app_count = applications_page.search("span.PSGRIDCOUNTER")[0].content.split(' of ')[1].to_i
  remaining_apps_count = inquiry_page.search("#UW_CO_JOBSRCHDW_UW_CO_MAX_NUM_APPL")[0].content.to_i
  offer_count = (remaining_apps_count + active_app_count) - MAX_APPLICATIONS

  puts "Offer count is currently #{offer_count}."

  applications_page.search('table.PSLEVEL1GRID')[1].search('tr')[1..-1].collect do |application|
    tds = application.search('td')
    
    new_applications[tds[JOB_ID_INDEX].content.strip] = {
     'title' => tds[JOB_TITLE_INDEX].content.strip,
     'employer' => tds[EMPLOYER_INDEX].content.strip,
     'status' => (tds[STATUS_INDEX].content.scan(/[\w ]/).join.length.zero? ? tds[JOB_STATUS_INDEX].content.scan(/[\w ]/).join : tds[STATUS_INDEX].content.scan(/[\w ]/).join)
    }
  end

  cache = JSON.parse(File.open(CACHE_FILE).read) rescue {}
  old_applications = cache['apps'] || {} rescue {}
  old_offer_count = cache['offers'] || 0 rescue 0

  new_applications.each do |id, new|
    if old_applications[id] && old_applications[id]['status'] != new['status']
      content = []
      content << "Yo dawg,"
      content << "One of your job applications on JobMine just changed its status:"
      content << ""
      content << "\t#{new['title']} at #{new['employer']}"
      content << "\t\twent from \"#{old_applications[id]['status']}\" to \"#{new['status']}\""

      if offer_count == (1 + old_offer_count) && new['status'] == "Ranking Completed"
        content << ""
        content << "Also, according to The Glitch, you have an offer for this job."
        content << "Congratulations!"
        content << ""
        subject = "OFFER FROM #{new['employer']}";
      else
        content << ""
        content << "Congratulations...?"
        subject = "\"#{new['status']}\" for #{new['employer']}";
      end
      content << "tehjobminebot"


      response = PostageApp::Request.new(:send_message, {
        'headers'     => { 'from'     => "tehjobminebot <#{FROM_EMAIL}>",
                           'subject'  => subject },
        'recipients'  => DESTINATION_EMAIL,
        'content'     => { 'text/plain'  => content.join("\n") }
      }).send
      if response.fail?
        puts "Response failed! #{response.data}"
      end
      puts "\tApplication changed: \t#{new['title']} at #{new['employer']} (now #{new['status']})"
    end
  end
  # Write new JSON to file
  puts "Writing updated applications to cache..."
  File.open(CACHE_FILE, 'w').write(JSON.generate({:apps => new_applications, :offers => offer_count}))
  puts "Done!"
end

if CHECK_EVERY == :cron
  run
else
  Daemons.daemonize({
    :ontop => (not DAEMONIZE),
    :backtrace => true,
    :log_output => true,
    :app_name => 'jobmon',
  })  
  loop do
    run
    sleep (CHECK_EVERY * 60)
  end
end
