# encoding: utf-8
require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'
require 'digest/md5'
require File.dirname(__FILE__) + "/../config/test_config.rb"

include RR

# All ConnectionExtenders need to pass this spec
shared_examples_for "ConnectionExtender" do
  before(:each) do
  end

  it "referenced_tables should return those tables without primary key" do
    session = Session.new
    referenced_tables = session.left.referenced_tables(['table_with_manual_key'])
    referenced_tables.should == {'table_with_manual_key' => []}
  end

  it "select_cursor should handle zero result queries" do
    begin
      session = Session.new
      session.left.execute('delete from extender_no_record')
      result = session.left.select_cursor table: 'extender_no_record'
      result.next?.should be_falsey
    ensure

    end
  end

  it "select_cursor should work if row_buffer_size is smaller than table size" do
    begin
      session = Session.new

      session.left.execute('delete from scanner_records')

      session.left.insert_record('scanner_records', {
        id: 2,
        name: 'Bob - left database version'
      })

      session.left.insert_record('scanner_records', {
        id: 3,
        name: 'Charlie - exists in left database only'
      })

      session.left.insert_record('scanner_records', {
        id: 5,
        name: 'Eve - exists in left database only'
      })

      result = session.left.select_cursor(table: 'scanner_records', row_buffer_size: 2)
      result.next_row
      result.next_row
      result.next_row['id'].should == 5
      result.clear
    ensure
      session.left.execute('delete from scanner_records')
    end
  end

  it "select_cursor should allow iterating through records" do
    begin
      session = Session.new
      session.left.insert_record('extender_one_record', {
        id: 1,
        name: 'Alice'
      })
      result = session.left.select_cursor table: 'extender_one_record'
      result.next?.should be_truthy
      result.next_row.should == {'id' => 1, 'name' => 'Alice'}
    ensure
      session.left.execute('delete from extender_one_record')
    end
  end

  it "select_cursor next_row should raise if there are no records" do
    session = Session.new
    result = session.left.select_cursor table: 'extender_no_record'
    lambda {result.next_row}.should raise_error(RuntimeError, 'no more rows available')
  end

  it "should read and write binary data correctly" do
    session = Session.new

    org_data = File.new(File.dirname(__FILE__) + '/dolphins.jpg').read
    result_data = nil
    begin
      session.left.transaction_manager.begin_transaction
      session.left.insert_record('extender_type_check', {'id' => 6, 'binary_test' => org_data})

      row = session.left.select_one(
        'select md5(binary_test) as md5 from extender_type_check where id = 6'
      )
      row['md5'].should == Digest::MD5.hexdigest(org_data)

      result_data = session.left.select_record(
        table: "extender_type_check",
        row_keys: ["id" => 6]
      )['binary_test']
      Digest::MD5.hexdigest(result_data).should == Digest::MD5.hexdigest(org_data)
    ensure
      session.left.transaction_manager.rollback_transaction
    end
    result_data.force_encoding('BINARY').should == org_data.force_encoding('BINARY')
  end
end
