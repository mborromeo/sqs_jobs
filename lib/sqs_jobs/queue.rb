module SqsJobs
  
  class DeserializationError < StandardError
  end
  
  class Queue
    
    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/
    
    cattr_accessor :sqs_access_key, :sqs_secret_key, :sqs_queue_name, :sqs_server_host, :sqs_server_port, :sqs_multi_thread, :sqs_signature_version, :sqs_logger
    cattr_accessor :sqs_queue_uri, :sqs_object
    cattr_accessor :sqs_delay_between_jobs, :sqs_jobs_to_get
    
    def self.setup(params)
      Rails.logger.info "[SqsJobs] Setup"
      params.each { |k,value| send("#{k}=", value) }
      
      send("sqs_server_host=", 'queue.amazonaws.com') unless params.has_key?('sqs_server_host')
      send("sqs_server_port=", 443) unless params.has_key?('sqs_server_port')
      send("sqs_multi_thread=", false) unless params.has_key?('sqs_multi_thread')
      send("sqs_signature_version=", '1') unless params.has_key?('sqs_signature_version')
      send("sqs_logger=", Rails.logger) unless params.has_key?('sqs_logger')
    
      send("sqs_object=", Aws::SqsInterface.new(@@sqs_access_key, @@sqs_secret_key, {:server => @@sqs_server_host, :port => @@sqs_server_port, :multi_thread => @@sqs_multi_thread, :signature_version => @@sqs_signature_version, :logger => @@sqs_logger}))
      send("sqs_queue_uri=", @@sqs_object.create_queue(@@sqs_queue_name))
    end
    
    def self.clear()
      begin
        @@sqs_object.clear_queue(@@sqs_queue_uri)
      rescue
        Rails.logger.error "[SqsJobs] Something went wrong into SqsJobs::Queue.clear"
      end
    end
    
    def self.length()
      @@sqs_object.get_queue_length(@@sqs_queue_uri)
    end
    
    def self.enqueue(*args, &block)
      object = block_given? ? EvaledJob.new(&block) : args.shift

      unless object.respond_to?(:perform) || block_given?
        raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
      end
      
      self.push object.to_yaml
    end
    
    def self.push(object)
      begin
        @@sqs_object.send_message(@@sqs_queue_uri, object)
      rescue
        Rails.logger.error "[SqsJobs] Something went wrong into SqsJobs::Queue.push"
      end
    end
    
    def self.delete_job(receipthandle)
      Rails.logger.info "[SqsJobs] Deleting job with receipt handle #{receipthandle}"
      @@sqs_object.delete_message(@@sqs_queue_uri, receipthandle)
    end
    
    def self.process(jobscount)
      jobs = @@sqs_object.receive_message(@@sqs_queue_uri, jobscount)
      jobs.each do |job|
        handler = self.deserialize(job['Body'])
        begin
          handler.perform
          self.delete_job(job['ReceiptHandle'])
          Rails.logger.info "[SqsJobs] Job #{job['MessageId']} processed."
          return true
        rescue Exception => e
          Rails.logger.warn "[SqsJobs] Job #{job['MessageId']} failed."
          return false
        end
      end
    end
    
    private

      def self.deserialize(source)
        handler = YAML.load(source) rescue nil
        
        unless handler.respond_to?(:perform)
          if handler.nil? && source =~ ParseObjectFromYaml
            handler_class = $1
          end
          self.attempt_to_load(handler_class || handler.class)
          handler = YAML.load(source)
        end

        return handler if handler.respond_to?(:perform)

        raise DeserializationError,
          '[SqsJobs] Job failed to load: Unknown handler. Try to manually require the appropiate file.'
      rescue TypeError, LoadError, NameError => e
        raise DeserializationError,
          "[SqsJobs] Job failed to load: #{e.message}. Try to manually require the required file."
      end

      # Constantize the object so that ActiveSupport can attempt
      # its auto loading magic. Will raise LoadError if not successful.
      def self.attempt_to_load(klass)
         klass.constantize
      end
  end
  
  class EvaledJob
    def initialize
      @job = yield
    end

    def perform
      eval(@job)
    end
  end
  
end