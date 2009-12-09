puts "Creating sample config file..."
FileUtils.cp_r(File.join(File.dirname(__FILE__), 'samples', 'sqsjobs.yml'), File.join(RAILS_ROOT, 'config', 'sqsjobs.yml'))
puts "Creating daemon control script..."
FileUtils.cp_r(File.join(File.dirname(__FILE__), 'samples', 'sqsjobs'), File.join(RAILS_ROOT, "script", 'sqsjobs'))

puts
puts "SqsJobs - A Sqs backed job queue"
puts "--------------------------------"
puts
puts " * Enter your AWS access key, secret key and queue name into config/sqsjobs.yml"
puts " * Start writing your background jobs as this example (put this into app/models/jobs.rb)"
puts "   module Jobs"
puts "     class ComputeMassiveStuffForUser < Struct.new(:user_id)"
puts "       user = User.find(:user_id)"
puts "       user.calculate_recommendations"
puts "     end"
puts
puts "     class SendMessageToUser < Struct.new(:user_id, :message)"
puts "       user = User.find(:user_id)"
puts "       user.send_message message"
puts "     end"
puts "   end"
puts 
puts " * Add jobs to queue as follows:"
puts "     SqsJobs::Queue.enqueue(Jobs::ComputeMassiveStuffForUser.new(3))"
puts "     or"
puts "     SqsJobs::Queue.enqueue(Jobs::SendMessageToUser.new(4, 'Hello from a separate process!'))"
puts 
puts " * Start/stop/restart jobs workers with script/sqsjob start/stop/restart"
puts
puts "SqsJobs contains portions of code from Delayed_Job and Shopify_App plugins."
puts "Enjoy!"