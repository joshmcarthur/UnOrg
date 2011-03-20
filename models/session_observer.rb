class SessionObserver
  include DataMapper::Observer
  
  observe Session
  
  before_transition :to => :sessionified do
    #TODO create the session? 
  end
  
end
