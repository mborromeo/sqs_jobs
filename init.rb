require File.dirname(__FILE__) + '/lib/sqs_jobs'

begin
  require 'right_aws'
rescue MissingSourceFile
  STDERR.puts "[SqsJobs] ERROR - This plugin requires the right_aws gem. Run `sudo gem install right_aws`."
  exit(1)
end

if ENV['SQSJOBS_ACCESS_KEY'] && ENV['SQSJOBS_SECRET_KEY'] && ENV['SQSJOBS_QUEUE_NAME']
  Rails.logger.info "[SqsJobs] Loading credentials from environment"
  
  ShopifyAPI::Session.setup(:sqs_access_key => ENV['SQSJOBS_ACCESS_KEY'], :sqs_secret_key => ENV['SQSJOBS_SECRET_KEY'], :sqs_queue_name => ENV['SQSJOBS_QUEUE_NAME'])
else
  config = File.join(Rails.root, "config/sqsjobs.yml")
  
  if File.exist?(config)
    Rails.logger.info "[SqsJobs] Loading Sqs credentials from config/sqsjobs.yml"
    
    credentials = YAML.load(File.read(config))[Rails.env]
    SqsJobs::Queue.setup(credentials)
  else
    Rails.logger.warn '[SqsJobs] Plugin installed but no config/sqsjobs.yml found.'
  end
end