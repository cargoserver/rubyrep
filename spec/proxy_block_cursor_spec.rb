require File.dirname(__FILE__) + '/spec_helper.rb'

include RR

describe ProxyBlockCursor do
  before(:each) do
    @session = create_mock_proxy_connection 'dummy_table', ['dummy_id']
    @cursor = ProxyBlockCursor.new @session, 'dummy_table'
  end

  it "initialize should super to ProxyCursor" do
    @cursor.table.should == 'dummy_table'
  end

  it "next? should return true if there is an already loaded unprocessed row" do
    @cursor.last_row = :dummy_row
    @cursor.next?.should be_truthy
  end

  it "next? should return true if the database cursor has more rows" do
    table_cursor = mock("DBCursor")
    table_cursor.should_receive(:next?).and_return(true)
    @cursor.cursor = table_cursor

    @cursor.next?.should be_truthy
  end

  it "next? should return false if there are no loaded or unloaded unprocessed rows" do
    table_cursor = mock("DBCursor")
    table_cursor.should_receive(:next?).and_return(false)
    @cursor.cursor = table_cursor

    @cursor.next?.should be_falsey
  end

  it "next_row should return last loaded unprocessed row or nil if there is none" do
    @cursor.last_row = :dummy_row

    @cursor.next_row.should == :dummy_row
    @cursor.last_row.should be_nil
  end

  it "next_row should return next row in database if there is no loaded unprocessed row available" do
    table_cursor = mock("DBCursor")
    table_cursor.should_receive(:next_row).and_return(:dummy_row)
    @cursor.cursor = table_cursor

    @cursor.next_row.should == :dummy_row
  end

  it "reset_checksum should create a new empty SHA1 digest" do
    @cursor.digest = :dummy_digest
    @cursor.reset_checksum
    @cursor.digest.should be_an_instance_of(Digest::SHA1)
  end

  it "reset_checksum should reset block variables" do
    @cursor.reset_checksum
    @cursor.row_checksums.should == []
    @cursor.current_row_cache_size.should == 0
    @cursor.row_cache.should == {}

  end

  it "update_checksum should update the existing digests" do
    dummy_row1 = {'dummy_id' => 'dummy_value1'}
    dummy_row2 = {'dummy_id' => 'dummy_value2'}

    @cursor.reset_checksum
    @cursor.update_checksum dummy_row1
    @cursor.update_checksum dummy_row2

    @cursor.current_checksum.should == Digest::SHA1.hexdigest(Marshal.dump(dummy_row1) + Marshal.dump(dummy_row2))
    @cursor.row_checksums.should == [
      {:row_keys => dummy_row1, :checksum => Digest::SHA1.hexdigest(Marshal.dump(dummy_row1))},
      {:row_keys => dummy_row2, :checksum => Digest::SHA1.hexdigest(Marshal.dump(dummy_row2))},
    ]

    @cursor.row_cache.should == {
      Digest::SHA1.hexdigest(Marshal.dump(dummy_row1)) => Marshal.dump(dummy_row1),
      Digest::SHA1.hexdigest(Marshal.dump(dummy_row2)) => Marshal.dump(dummy_row2)
    }
  end

  it "retrieve_row_cache should retrieve the specified elements" do
    @cursor.row_cache = {'dummy_checksum' => 'bla'}
    @cursor.retrieve_row_cache(['non_cached_row_checksum', 'dummy_checksum']).should ==
      {'dummy_checksum' => 'bla'}
  end

  it "current_checksum should return the current checksum" do
    digest = mock("Digest")
    digest.should_receive(:hexdigest).and_return(:dummy_checksum)
    @cursor.digest = digest

    @cursor.current_checksum.should == :dummy_checksum
  end

  it "checksum should reset the current digest" do
    @cursor.reset_checksum # need to call it now so that for the call to checksum it can be mocked
    @cursor.should_receive(:reset_checksum)
    @cursor.should_receive(:next?).and_return(false)
    @cursor.checksum :proxy_block_size => 1
  end

  it "checksum should complain if neither :proxy_block_size nor :max_row are provided" do
    lambda {@cursor.checksum}.should raise_error(
      RuntimeError, 'options must include either :proxy_block_size or :max_row')
  end

  it "checksum should verify options" do
    lambda {@cursor.checksum}.should raise_error(
      RuntimeError, 'options must include either :proxy_block_size or :max_row')
    lambda {@cursor.checksum(:proxy_block_size => 0)}.should raise_error(
      RuntimeError, ':proxy_block_size must be greater than 0')
  end

end
