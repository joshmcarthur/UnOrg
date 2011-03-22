require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "UnOrg" do
  before(:each) do
    set :environment, :test
    
    Session.destroy
    Desire.destroy
    @session_valid_attributes = {:name => "Test Session 1", 
      :description => "`This is a code block`",
      :scheduled_for => Time.now + (60 * 60 * 24) * 90}
      
    @session = Session.create(@session_valid_attributes)
    
    @desire_valid_attributes = {:title => "Test Desire", 
      :author => "Tester", 
      :description => "`This is my description`"} 
    @desire = Desire.create(@desire_valid_attributes)      
  end
  
  describe Session do
    it "should create a valid object" do
      Session.create(:name => "Test Session 1", :description => "Hello", :scheduled_for => Time.now + (60 * 60 * 24)).saved?.should == true
    end
    
    it "should not create an invalid object" do
      Session.create(:name => nil, :description => "Hello", :scheduled_for => Time.now + 60).saved?.should == false
    end
    
    it 'should not create an object whose scheduled time is before now' do
      Session.create(:name => "Test session", :description => "Hello", :scheduled_for => Time.now - 60).saved?.should == false
    end
    
    it "should have an initial state" do
      Session.all.first.state == "proposed"
    end
    
    it "should advance from proposed to scheduled" do
      @session.schedule!
      @session.state.should == "scheduled"
    end
    
    it 'should advance from scheduled to finished' do
      @session.schedule!
      @session.finish!
      @session.state.should == "finished"
    end
    
    it 'should display scope Sessions' do
      #Create a Session scheduled for now
      Session.create(:name => "Test session", :description => "Hello", :scheduled_for => Time.now)
      #We already had a session created, this is the only one we should be able to see.
      Session.display.length.should == 1
    end
  end
  
  describe Desire do
    it 'should not retrieve a closed desire' do
      #The desire that has been created is open
      @desire = Desire.create(:title => "New Desire", :author => "Tester", :description => "A new desire")
      @desire.close!
      Desire.all.include?(@desire).should_not == true
    end
    
    it 'should retrieve only active desires (Unclosed and Unresolved) when requested' do
      #So there is currently one active desire in the database.
      #Let's make a closed one and a resolved one, and make sure only that once appears.
      closed_desire = Desire.create(:title => "Closed Desire", :author => "Tester", :description => "A closed desire")
      resolved_desire = Desire.create(:title => "Resolved Desire", :author => "Tester", :description => "A resolved desire")
      closed_desire.close!
      resolved_desire.resolve!
      Desire.open.include?(closed_desire).should_not == true
      Desire.open.include?(resolved_desire).should_not == true
    end
    
    it 'should upvote correctly' do
      @desire.votes.should == 0
      @desire.upvote!
      @desire.votes.should == 1
      @desire.saved?.should == true
    end
    it 'should advance from new to resolved' do
      @desire.state.should == "new"
      @desire.resolve!
      @desire.state.should == "resolved"
    end
    
    it 'should advance from new to closed' do
      @desire.state.should == "new"
      @desire.close!
      @desire.state.should == "closed"
    end
    
    it 'should not advance from resolved to closed' do
      @desire.resolve!
      lambda { @desire.close! }.should raise_exception(StateMachine::InvalidTransition)
    end
    
    it 'should create a valid object' do
      @desire.valid?.should == true
      @desire.saved?.should == true
    end
    
    it 'should not create an invalid object' do
      @desire.title = nil
      @desire.valid?.should == false
      @desire.save.should == false
    end
  end
  
  describe "UnOrg Service" do
    describe 'GET /' do
      it 'should respond to GET /' do
        get '/'
        last_response.should be_ok
        
        #Our response should contain the name of one of our sessions somewhere
        last_response.body.include?(@session.name).should == true
        last_response.body.include?(@desire.title).should ==  true
      end
    end
    
    describe 'GET /sessions/new' do
      it 'should respond to GET /sessions/new' do
        get '/sessions/new'
        last_response.should be_ok
        last_response.body.include?("session[name]").should == true
      end
    end
    
    describe 'GET /sessions/:id/edit' do
      it 'should respond to GET /sessions/:id/edit' do
        get "/sessions/#{@session.id}/edit"
        last_response.should be_ok
        last_response.body.include?("session[name]").should == true
        last_response.body.include?(@session.name).should == true
      end
      
      it 'should return a 404 message if the object does not exist' do
        get "/sessions/1024/edit"
        last_response.status.should == 404
      end
    end
    
    describe 'POST /sessions/:id/update' do
      it 'should update object fields' do
        post "/sessions/#{@session.id}/update", :session => {:name => "Session Redux", :scheduled_for => Time.now + 60}
        last_response.status.should == 302
        
        #We need to reload the object to check changes
        @session = Session.get(@session.id)
        
        @session.name.should == "Session Redux"
      end
      
      it 'should not update object fields if data is invalid' do
        post "/sessions/#{@session.id}/update", :session => {:name => ""}
        @session.name.should_not == ""
      end
      
      it 'should return a 404 message if the object does not exist' do
        post "/sessions/999/update"
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end
    
    describe 'POST /sessions/:id/delete' do
      it 'should delete an object' do
        post "/sessions/#{@session.id}/delete"
        last_response.status.should == 302
        Session.display.include?(@session).should_not == true
      end
      
      it 'should return a 404 message if the object does not exist' do
        post "/sessions/999/delete"
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end
    
    describe 'POST /sessions' do
      it 'should create a session given valid data' do
        Session.destroy
        post '/sessions', :session => @session_valid_attributes
        last_response.status.should == 302
        
        Session.display.length.should == 1
      end
      
      it 'should not create a session given invalid data' do
        post '/sessions', :session => @session_valid_attributes.merge({:name => ""})
        last_response.should_not be_ok
        last_response.status.should == 400
      end
    end
    
    describe 'GET /desires/new' do
      it 'should correctly render the new form' do
        get '/desires/new'
        last_response.should be_ok
        last_response.body.include?("desire[title]").should == true
      end      
    end
    
    describe 'POST /desires/:id/upvote' do
      it 'should call the action, and successfully redirect' do
        post "/desires/#{@desire.id}/upvote"
        last_response.status.should == 302
      end
      
      it 'should have incremented the votes after calling upvote' do
        post "/desires/#{@desire.id}/upvote"
        @desire = Desire.get(@desire.id)
        @desire.votes.should == 1
      end
      
      it 'should return a 404 message if the desire does not exist' do
        post "/desires/999/upvote"
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end
    
    describe 'POST /desires/:id/delete' do
      it 'should call the action and successfully redirect' do
        post "/desires/#{@desire.id}/delete"
        last_response.status.should == 302        
      end
      
      it 'should have deleted the object after calling delete' do
        post "/desires/#{@desire.id}/delete"
        Desire.get(@desire.id).should == nil
      end
      
      it 'should return a 404 message if the object does not exist' do
        post "/desires/999/delete"
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end
    
    describe 'POST /desires' do
      it 'should call the action and successfully redirect' do
        post "/desires", :desire => @desire_valid_attributes
        last_response.status.should == 302
      end
      
      it 'should create an object given valid attributes' do
        Desire.destroy
        post "/desires", :desire => @desire_valid_attributes
        Desire.all.length.should == 1
      end
      
      it 'should not create an object given invalid attributes' do
        Desire.destroy
        post "/desires", :desire => @desire_valid_attributes.merge(:title => "")
        Desire.all.length.should == 0
      end
      
      it 'should return an invalid data error given invalid attributes' do
        post "/desires", :desire => @desire_valid_attributes.merge(:title => "")
        last_response.should_not be_ok
        last_response.status.should == 400
      end
    end

    describe 'GET /desires/:id/edit' do
      it 'should call the action for an object that exists' do
        get "/desires/#{@desire.id}/edit"
        last_response.should be_ok
        last_response.body.include?("desire[title]").should == true
      end
      
      it 'should return a 404 error if the object does not exist' do
        get '/desires/999/edit'
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end
    
    describe 'POST /desires/:id/update' do
      it 'should update object fields' do
        post "/desires/#{@desire.id}/update", :desire => {:title => "Desire Redux", :author => "Tester"}
        last_response.status.should == 302
        
        #We need to reload the object to check changes
        @desire = Desire.get(@desire.id)
        
        @desire.title.should == "Desire Redux"
      end
      
      it 'should not update object fields if data is invalid' do
        post "/desires/#{@desire.id}/update", :desire => {:title => ""}
        @desire = Desire.get(@desire.id)
        @desire.title.should_not == ""
      end
      
      it 'should return a 404 message if the object does not exist' do
        post "/desires/999/update"
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end
    
    describe 'POST /desires/:id/resolve' do
      it 'should process and redirect if the object exists' do
        post "/desires/#{@desire.id}/resolve"
        last_response.status.should == 302
      end
      
      it 'should update the desire state' do
        post "/desires/#{@desire.id}/resolve"
        @desire = Desire.get(@desire.id)
        @desire.state.should == "resolved"
      end
      
      it 'should return a 404 message if the object does not exist' do
        post "/desires/999/resolve"
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end
    
    describe 'POST /desires/:id/close' do
      it 'should process and redirect if the object exists' do
        post "/desires/#{@desire.id}/close"
        last_response.status.should == 302
      end

      it 'should return a 404 message if the object does not exist' do
        post "/desires/999/close"
        last_response.should_not be_ok
        last_response.status.should == 404
      end
    end      
  end
end
