module SqsJobs
  class Worker
    
    cattr_accessor :sqs_jobs_to_get, :sqs_delay_between_jobs
    
    def initialize(options)
      @@sqs_jobs_to_get = options['sqs_jobs_to_get']
      @@sqs_delay_between_jobs = options['sqs_delay_between_jobs']
    end
    
    def start
      Rails.logger.info "[SqsJobs] Starting worker PID #{Process.pid} - Host #{Socket.gethostname}"
      
      trap('TERM') { Rails.logger.info '[SqsJobs] Got TERM - Exiting.'; $exit = true }
      trap('INT')  { Rails.logger.info '[SqsJobs] Got INT - Exiting.'; $exit = true }
      
      loop do
        SqsJobs::Queue.process(@@sqs_jobs_to_get)
        break if $exit
        sleep(@@sqs_delay_between_jobs)
      end
    end
  end
end