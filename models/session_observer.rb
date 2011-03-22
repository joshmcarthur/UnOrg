class SessionObserver
  include DataMapper::Observer
  require 'rdiscount'
  
  observe Session
  
  before(:save) Proc.new { |session| 
    session.description = RDiscount.new(session.description, :smart, :filter_html)
  }

end
