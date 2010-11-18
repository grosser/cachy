require 'spec/spec_helper'
require 'spec/mem_cache'
require 'cachy/memcache_timeout_protection'

describe "MemCache timeout protection" do
  before do
    MemCache.read_error_callback = nil
  end

  let(:cache){ MemCache.new }

  def simulate_timeout
    cache.stub!(:stubable_cache_get).and_raise('IO timeout')
  end

  it "has no errors by default" do
    cache.read_error_occurred.should == nil
  end

  it "catches timeout errors" do
    MemCache.read_error_callback = lambda{}
    simulate_timeout
    cache.get('x').should == nil
    cache.read_error_occurred.should == true
  end

  it "resets error_occurred to false after successful get" do
    MemCache.read_error_callback = lambda{}
    simulate_timeout
    cache.get('x').should == nil
    cache.stub!(:stubable_cache_get).and_return 1
    cache.get('x').should == 1
    cache.read_error_occurred.should == false
  end

  it "raises if no callback is given" do
    simulate_timeout
    lambda{
      cache.get('x').should == nil
    }.should raise_error
    cache.read_error_occurred.should == true
  end

  it "calls the callback" do
    MemCache.read_error_callback = lambda{ 1 }
    simulate_timeout
    cache.get('x').should == 1
    cache.read_error_occurred.should == true
  end
end