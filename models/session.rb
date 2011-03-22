class Session
  include DataMapper::Resource
  require 'state_machine'
  require 'rdiscount'
  
  property :id, Serial
  property :name, String, :required => true
  property :scheduled_for, DateTime, :required => true
  property :description, Text
  property :state, String, :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  #Validations
  validates_with_block :scheduled_for do
    return false if self.scheduled_for.nil?
    if DateTime.now > self.scheduled_for
      return [false, "Scheduled for time cannot be before the current time."]
    else
      return true
    end
  end
  
  #Scoping
  def self.display
    self.all(:scheduled_for.gte => Time.now)
  end
  
  state_machine :initial => :proposed do
    event :schedule do
      transition :proposed => :scheduled
    end
    
    event :finish do
      transition [:proposed, :scheduled] => :finished
    end
  end
end
