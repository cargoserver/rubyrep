require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + "/../config/test_config.rb"

include RR

shared_examples_for 'Committer' do
  before(:each) do
    @old_committers = Committers.committers
  end

  after(:each) do
    Committers.instance_variable_set :@committers, @old_committers
  end

  it "committers should return empty hash if nil" do
    Committers.instance_variable_set :@committers, nil
    Committers.committers.should == {}
  end

  it "committers should return the registered committers" do
    Committers.instance_variable_set :@committers, :dummy_data
    Committers.committers.should == :dummy_data
  end

  it "register should register the provided commiter" do
    Committers.instance_variable_set :@committers, nil
    Committers.register :a_key => :a
    Committers.register :b_key => :b
    Committers.committers[:a_key].should == :a
    Committers.committers[:b_key].should == :b
  end
end


shared_examples_for "Committer" do
  it "should support the right constructor interface" do
    session = mock("session")
    session.should_receive(:left).any_number_of_times \
      .and_return(mock("left connection", :null_object => true))
    session.should_receive(:right).any_number_of_times \
      .and_return(mock("right connection", :null_object => true))
    @committer.class.new session
  end

  it "should proxy insert_record, update_record and delete_record calls" do
    left_connection = mock("left connection", :null_object => true)
    left_connection.should_receive(:insert_record).with("left", :dummy_insert_values)

    right_connection = mock("right connection", :null_object => true)
    right_connection.should_receive(:update_record).with("right", :dummy_update_values, :dummy_org_key)
    right_connection.should_receive(:delete_record).with("right", :dummy_delete_values)

    session = mock("session")
    session.should_receive(:left).any_number_of_times.and_return(left_connection)
    session.should_receive(:right).any_number_of_times.and_return(right_connection)

    committer = @committer.class.new session

    committer.insert_record :left, 'left', :dummy_insert_values
    committer.update_record :right, 'right', :dummy_update_values, :dummy_org_key
    committer.delete_record :right, 'right', :dummy_delete_values
  end

  it "should support finalize" do
    @committer.finalize(false)
  end
end

describe Committers::DefaultCommitter do
  before(:each) do
    @session = mock("session")
    @session.should_receive(:left).any_number_of_times.and_return(:left_connection)
    @session.should_receive(:right).any_number_of_times.and_return(:right_connection)
    @committer = Committers::DefaultCommitter.new @session
  end

  it "should register itself" do
    Committers.committers[:default].should == Committers::DefaultCommitter
  end

  it "initialize should store the provided parameters" do
    @committer.session.should == @session
    @committer.connections \
      .should == {:left => @session.left, :right => @session.right}
  end

  it "new_transaction? should return false" do
    @committer.new_transaction?.should be_falsey
  end

  it_should_behave_like "Committer"
end
