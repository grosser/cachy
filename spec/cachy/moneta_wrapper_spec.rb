require 'spec/spec_helper'

class TestMoneta
  def initialize
    @wrapped = {}
  end

  def store(key, object, options={})
    raise 'nope!' if options[:expires_in] and not options[:expires_in].is_a? Numeric
    @wrapped[key] = object
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

describe "Cachy::MonetaWrapper" do
  before :all do
    @cache = TestMoneta.new
    Cachy.cache_store = @cache
  end

  before do
    @cache.clear
  end

  it "is wrapped" do
    Cachy.cache_store.class.should == Cachy::MonetaWrapper
  end

  it "can cache" do
    Cachy.cache(:x){ 'SUCCESS' }
    Cachy.cache(:x){ 'FAIL' }.should == 'SUCCESS'
  end

  it "can cache without expires" do
    @cache.should_receive(:store).with('x_v1', 'SUCCESS', {})
    Cachy.cache(:x){ 'SUCCESS' }
  end

  it "can cache with expires" do
    @cache.should_receive(:store).with('x_v1', 'SUCCESS', :expires_in=>1)
    Cachy.cache(:x, :expires_in=>1){ 'SUCCESS' }
  end

  it "can expire" do
    @cache.should_receive(:delete).with('x_v1')
    Cachy.expire(:x)
  end
end