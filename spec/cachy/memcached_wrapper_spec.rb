require 'spec/spec_helper'

class TestMemcached
  def initialize
    @wrapped = {}
  end

  def set(key, object, ttl = nil)
    raise 'nope!' if ttl.is_a? Hash or (ttl and not ttl.is_a? Numeric)
    @wrapped[key] = object
  end

  def get(key)
    @wrapped[key]
  end

  def [](x)
    @wrapped[x]
  end

  def clear
    @wrapped.clear
  end

  def delete(key)
    @wrapped.delete(key)
  end
end

describe "Cachy::MemcachedWrapper" do
  before :all do
    @cache = TestMemcached.new
    Cachy.cache_store = @cache
  end

  before do
    @cache.clear
  end

  it "is wrapped" do
    Cachy.cache_store.class.should == Cachy::MemcachedWrapper
  end

  it "can cache" do
    Cachy.cache(:x){ 'SUCCESS' }
    Cachy.cache(:x){ 'FAIL' }.should == 'SUCCESS'
  end

  it "can cache without expires" do
    @cache.should_receive(:set).with('x_v1', 'SUCCESS', 0)
    Cachy.cache(:x){ 'SUCCESS' }
  end

  it "can cache with expires" do
    @cache.should_receive(:set).with('x_v1', 'SUCCESS', 1)
    Cachy.cache(:x, :expires_in=>1){ 'SUCCESS' }
  end

  it "can expire" do
    @cache.should_receive(:delete).with('x_v1')
    Cachy.expire(:x)
  end
end