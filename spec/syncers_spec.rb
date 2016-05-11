require File.dirname(__FILE__) + '/spec_helper.rb'

include RR

describe Syncers do
  before(:each) do
    @old_syncers = Syncers.syncers
  end

  after(:each) do
    Syncers.instance_variable_set :@syncers, @old_syncers
  end

  it "syncers should return empty hash if nil" do
    Syncers.instance_variable_set :@syncers, nil
    Syncers.syncers.should == {}
  end

  it "syncers should return the registered syncers" do
    Syncers.instance_variable_set :@syncers, :dummy_data
    Syncers.syncers.should == :dummy_data
  end

  it "configured_syncer should return the correct syncer as per :syncer option, if both :syncer and :replicator is configured" do
    options = {
      :syncer => :two_way,
      :replicator => :key2
    }
    Syncers.configured_syncer(options).should == Syncers::TwoWaySyncer
  end

  it "configured_syncer should return the correct syncer as per :replicator option if no :syncer option is provided" do
    options = {:replicator => :two_way}
    Syncers.configured_syncer(options).should == Syncers::TwoWaySyncer
  end

  it "register should register the provided commiter" do
    Syncers.instance_variable_set :@syncers, nil
    Syncers.register :a_key => :a
    Syncers.register :b_key => :b
    Syncers.syncers[:a_key].should == :a
    Syncers.syncers[:b_key].should == :b
  end
end

describe Syncers::OneWaySyncer do
  before(:each) do
    Initializer.configuration = standard_config
  end

  it "should register itself" do
    Syncers::syncers[:one_way].should == Syncers::OneWaySyncer
  end

  it "initialize should store sync_helper" do
    sync = TableSync.new(Session.new, 'scanner_records')
    helper = SyncHelper.new(sync)
    syncer = Syncers::OneWaySyncer.new(helper)
    syncer.sync_helper.should == helper
  end

  it "default_option should return the correct default options" do
    Syncers::OneWaySyncer.default_options.should == {:left_record_handling=>:insert, :right_record_handling=>:insert, :sync_conflict_handling=>:ignore, :logged_sync_events=>[:ignored_conflicts]}
  end

  it "sync_difference should only delete if :delete option is given" do
    sync = TableSync.new(Session.new, 'scanner_records')
    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :left}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_not_receive(:delete_record)
    helper.should_not_receive(:update_record)
    syncer.sync_difference(:left, {:name => :dummy_record})
  end

  it "sync_difference should delete in the right database" do
    sync = TableSync.new(Session.new, 'scanner_records')
    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :left, left_record_handling: :delete}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_receive(:delete_record).with(:left, 'scanner_records', {name: :dummy_record})
    helper.should_not_receive(:update_record)
    helper.should_not_receive(:insert_record)
    syncer.sync_difference(:left, {name: :dummy_record})

    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :right, right_record_handling: :delete}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_receive(:delete_record).with(:right, 'scanner_records', {name: :dummy_record})
    syncer.sync_difference(:right, {name: :dummy_record})
  end

  it "sync_difference should not insert if :insert option is not true" do
    sync = TableSync.new(Session.new, 'scanner_records')
    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :left, right_record_handling: :ignore}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_not_receive(:delete_record)
    helper.should_not_receive(:update_record)
    helper.should_not_receive(:insert_record)
    syncer.sync_difference(:right, {name: :dummy_record})
  end

  it "sync_difference should insert in the right database" do
    sync = TableSync.new(Session.new, 'scanner_records')
    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :left, right_record_handling: :insert}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_not_receive(:delete_record)
    helper.should_not_receive(:update_record)
    helper.should_receive(:insert_record).with(:left, 'scanner_records', {name: :dummy_record})
    syncer.sync_difference(:right, {name: :dummy_record})

    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :right, left_record_handling: :insert}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_receive(:insert_record).with(:right, 'scanner_records', {name: :dummy_record})
    syncer.sync_difference(:left, {name: :dummy_record})
  end

  it "sync_difference should update the right values in the right database" do
    sync = TableSync.new(Session.new, 'scanner_records')
    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :left, sync_conflict_handling: :right_wins}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_not_receive(:delete_record)
    helper.should_receive(:update_record).with(:left, 'scanner_records', :right_record)
    helper.should_not_receive(:insert_record)
    syncer.sync_difference(:conflict, [:left_record, :right_record])

    helper = SyncHelper.new(sync)
    helper.stub(:sync_options).and_return(sync.sync_options.merge({:direction => :right, sync_conflict_handling: :left_wins}))
    syncer = Syncers::OneWaySyncer.new(helper)
    helper.should_receive(:update_record).with(:right, 'scanner_records', :left_record)
    syncer.sync_difference(:conflict, [:left_record, :right_record])
  end
end
