class Desire
  include DataMapper::Resource
  require 'state_machine'
  
  
  property :id, Serial
  property :title, String
  property :author, String
  property :votes, Integer, :default => 0
  property :description, Text
  property :created_at, DateTime
  property :updated_at, DateTime
  
  state_machine :initial => :new do
    event :resolve do
      transition :new => :resolved
    end
    
    event :close do
      transition :new => :close
    end
    
    event :sessionify do
      transition [:new, :resolved, :closed] => :sessionified
    end
  end
  
  def upvote!
    self.update_attribute(:votes, self.votes += 1)
  end
  
end
