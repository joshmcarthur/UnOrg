class Session
  include DataMapper::Resource
  require 'state_machine'
  
  property :id, Serial
  property :name, String
  property :scheduled_for, DateTime
  property :description, Text
  property :state, String
  property :created_at, DateTime
  property :updated_at, DateTime
  
  state_machine :initial => :proposed do
    event :bump do
      transition :proposed => :upvoted
    end
    
    event :plan do
      transition [:proposed, :upvoted] => :planned
    end
  end
end
