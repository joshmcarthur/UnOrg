class DesireObserver
  include DataMapper::Observer
  require 'rdiscount'
  
  observe Desire
  
  before(:save) Proc.new { |desire| 
    desire.description = RDiscount.new(desire.description, :smart, :filter_html)
  }
  
  before_transition :to => :sessionified do
    #TODO create the session? 
  end
  
end
