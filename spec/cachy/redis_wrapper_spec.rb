require 'spec_helper'

class TestRedis
  def self.to_s
    'Redis'
  end

  def initialize
    @wrapped = {}
  end

  def get(key)
    @wrapped[key]
  end

  def set(key, object)
    @wrapped[key] = object
  end

  def expire(key, seconds)
  end

  def clear
    @wrapped.clear
  end

  def del(key)
    @wrapped.delete(key)
  end
end

class TestRedisNamespace < TestRedis
  def self.to_s
    'Redis::Namespace'
  end

  def initialize(namespace)
    super()
    @namespace = namespace
  end

  def get(key)
    super(namespaced(key))
  end

  def set(key, object)
    super(namespaced(key), object)
  end

  def del(key)
    super(namespaced(key))
  end

  private

  def namespaced(key)
    "#{@namespace}:#{key}"
  end
end

describe "Cachy::RedisWrapper" do
  let(:yaml_ending) { RUBY_VERSION > '1.9' ? "\n...\n" : "\n" }

  context 'Redis' do
    before :all do
      @cache = TestRedis.new
      Cachy.cache_store = @cache
    end

    before do
      @cache.clear
    end

    it "is wrapped" do
      Cachy.cache_store.class.should == Cachy::RedisWrapper
    end

    it "can cache" do
      Cachy.cache(:x){ 'SUCCESS' }
      Cachy.cache(:x){ 'FAIL' }.should == 'SUCCESS'
    end

    it "can cache without expires" do
      @cache.should_receive(:set).with('x_v1', "--- SUCCESS#{yaml_ending}")
      @cache.should_not_receive(:expire)
      Cachy.cache(:x){ 'SUCCESS' }.should == 'SUCCESS'
    end

    it "can cache with expires" do
      @cache.should_receive(:set).with('x_v1', "--- SUCCESS#{yaml_ending}")
      @cache.should_receive(:expire).with('x_v1', 1)
      Cachy.cache(:x, :expires_in=>1){ 'SUCCESS' }.should == 'SUCCESS'
    end

    it "can expire" do
      @cache.should_receive(:del).with('x_v1')
      Cachy.expire(:x)
    end
  end

  context 'Redis::Namespace' do
    before :all do
      @cache = TestRedisNamespace.new(:test_namespace)
      Cachy.cache_store = @cache
    end

    before do
      @cache.clear
    end

    it "is wrapped" do
      Cachy.cache_store.class.should == Cachy::RedisWrapper
    end

    it "can cache" do
      Cachy.cache(:x) { 'SUCCESS' }
      Cachy.cache(:x) { 'FAIL' }.should == 'SUCCESS'
    end

    it "can cache without expires" do
      @cache.should_receive(:set).with('x_v1', "--- SUCCESS#{yaml_ending}")
      @cache.should_not_receive(:expire)
      Cachy.cache(:x){ 'SUCCESS' }.should == 'SUCCESS'
    end

    it "can cache with expires" do
      @cache.should_receive(:set).with('x_v1', "--- SUCCESS#{yaml_ending}")
      @cache.should_receive(:expire).with('x_v1', 1)
      Cachy.cache(:x, :expires_in=>1){ 'SUCCESS' }.should == 'SUCCESS'
    end

    it "can expire" do
      @cache.should_receive(:del).with('x_v1')
      Cachy.expire(:x)
    end
  end
end
