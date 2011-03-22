class Desire
  include DataMapper::Resource
  require 'state_machine'
  require 'rdiscount'
  
  
  property :id, Serial
  property :title, String, :required => true
  property :author, String
  property :votes, Integer, :default => 0, :required => true
  property :description, Text
  property :created_at, DateTime
  property :updated_at, DateTime

  default_scope(:default).update(:conditions => ["state != 'closed'"])
  
  def self.open
    self.all(:state.not => "closed", :state.not => "resolved")
  end
    
  state_machine :initial => :new do
    event :resolve do
      transition :new => :resolved
    end
    
    event :close do
      transition :new => :closed
    end
    
    event :sessionify do
      transition [:new, :resolved, :closed] => :sessionified
    end
  end
  
  def upvote!
    (self.votes +=1) && self.save
  end
  
end
