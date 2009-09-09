require 'spec/spec_helper'

TEST_CACHE = TestCache.new

describe Cachy do
  before :all do
    Cachy.cache_store = TEST_CACHE
  end

  before do
    TEST_CACHE.clear
  end
  
  describe :cache do
    it "caches" do
      Cachy.cache(:my_key){ "X" }.should == "X"
      Cachy.cache(:my_key){ "ABC" }.should == "X"
    end
    
    it "expires" do
      Cachy.cache(:his_key, :expires_in=> -100){ 'X' }.should == 'X'
      Cachy.cache(:his_key, :expires_in=> -100){ 'X' }.should == 'X'
    end
    
    it "sets cache to intermediate value while running expensive query" do
      Cachy.cache(:my_key, :while_running=>'A') do
        Cachy.cache(:my_key){ 'X' }.should == 'A'
      end
    end

    it "can set while_running to false" do
      Cachy.cache(:my_key, :while_running=>false) do
        Cachy.cache(:my_key){ 'X' }.should == false
      end
    end

    it "can not set while_running to nil" do
      Cachy.should_receive(:warn)
      Cachy.cache(:my_key, :while_running=>nil) do
        Cachy.cache(:my_key){ 'X' }.should == "X"
      end
    end

    it "can cache false" do
      Cachy.cache(:x){ false }.should == false
      Cachy.cache(:x){ true }.should == false
    end

    it "does not cache nil" do
      Cachy.cache(:x){ nil }.should == nil
      Cachy.cache(:x){ true }.should == true
    end
  end

  describe :expire do
    it "expires the cache for all languages" do
      Cachy.cache(:my_key){ "without_locale" }

      locales = [:de, :en, :fr]
      locales.each do |l|
        Cachy.stub!(:locale).and_return l
        Cachy.cache(:my_key){ l }
      end

      TEST_CACHE.keys.select{|k| k=~ /my_key/}.size.should == 4
      Cachy.stub!(:locales).and_return locales
      Cachy.expire(:my_key)
      TEST_CACHE.keys.select{|k| k=~ /my_key/}.size.should == 0
    end

    it "does not expire other keys" do
      Cachy.cache(:another_key){ 'X' }
      Cachy.cache(:my_key){ 'X' }
      Cachy.cache(:yet_another_key){ 'X' }
      Cachy.expire :my_key
      TEST_CACHE.keys.should include("another_key_v1")
      TEST_CACHE.keys.should include("yet_another_key_v1")
    end

    it "expires the cache when no available_locales are set" do
      Cachy.cache(:another_key){ "X" }
      Cachy.cache(:my_key){ "X" }

      TEST_CACHE.keys.select{|k| k=~ /my_key/}.size.should == 1
      Cachy.expire(:my_key)
      TEST_CACHE.keys.select{|k| k=~ /my_key/}.size.should == 0
    end

    it "expires the cache with prefix" do
      key = 'views/my_key_v1'
      TEST_CACHE.write(key, 'x')
      TEST_CACHE.read(key).should_not == nil
      Cachy.expire(:my_key, :prefix=>'views/')
      TEST_CACHE.read(key).should == nil
    end
  end

  describe :expire_view do
    it "expires the cache with prefix" do
      key = 'views/my_key_v1'
      TEST_CACHE.write(key, 'x')
      TEST_CACHE.read(key).should_not == nil
      Cachy.expire_view(:my_key)
      TEST_CACHE.read(key).should == nil
    end
  end

  describe :key do
    it "builds based on cache_key" do
      user = mock(:cache_key=>'XXX',:something_else=>'YYY')
      Cachy.key(:my_key, 1, user, "abc").should == 'my_key_1_XXX_abc_v1'
    end

    it "adds current_language" do
      Cachy.stub!(:locale).and_return :de
      Cachy.key(:x).should == "x_v1_de"
    end

    it "raises on unknown options" do
      lambda{Cachy.key(:x, :asdasd=>'asd')}.should raise_error
    end

    it "gets the locale from I18n" do
      module I18n
        def self.locale
          :de
        end
      end
      key = Cachy.key(:x)
      Object.send :remove_const, :I18n #cleanup
      key.should == "x_v1_de"
    end

    describe "with :hash_key" do
      before do
        @hash = '3b2b8f418849bc73071375529f8515be'
      end

      after do
        Cachy.hash_keys = false
      end

      it "hashed the key to a stable value" do
        Cachy.key(:xxx, :hash_key=>true).should == @hash
      end

      it "changes when key changes" do
        Cachy.key(:xxx, :hash_key=>true).should_not == Cachy.key(:yyy, :hash_key=>true)
      end

      it "changes when arguments change" do
        Cachy.key(:xxx, :hash_key=>true).should_not == Cachy.key(:xxx, 1, :hash_key=>true)
      end

      it "can be triggered by Cachy.hash_keys" do
        Cachy.hash_keys = true
        Cachy.key(:xxx).should == @hash
      end
    end

    describe "with :keys" do
      it "is stable" do
        Cachy.key(:x, :keys=>'asd').should == Cachy.key(:x, :keys=>'asd')
      end

      it "changes when dependent key changes" do
        lambda{
          Cachy.increment_key('asd')
        }.should change{Cachy.key(:x, :keys=>'asd')}
      end

      it "is different for different keys" do
        Cachy.key(:x, :keys=>'xxx').should_not == Cachy.key(:x, :keys=>'yyy')
      end
    end

    describe 'with :without_locale' do
      it "is stable with same locale" do
        Cachy.stub!(:locale).and_return :de
        Cachy.key(:x, :without_locale=>true).should == Cachy.key(:x, :without_locale=>true)
      end

      it "is stable with different locales" do
        Cachy.stub!(:locale).and_return :de
        de_key = Cachy.key(:x, :without_locale=>true)
        Cachy.stub!(:locale).and_return :en
        Cachy.key(:x, :without_locale=>true).should == de_key
      end
    end

    describe 'with :locale' do
      it "changes the default key" do
        Cachy.key(:x, :locale=>:de).should_not == Cachy.key(:x)
      end

      it "is a different key for different locales" do
        Cachy.key(:x, :locale=>:de).should_not == Cachy.key(:x, :locale=>:en)
      end

      it "is the same key for the same locales" do
        Cachy.key(:x, :locale=>:de).should == Cachy.key(:x, :locale=>:de)
      end
    end
  end

  describe :key_versions do
    before do
      Cachy.key_versions = {}
      Cachy.key_versions.should == {}
    end

    it "adds a key when cache is called the first time" do
      Cachy.cache(:xxx){1}
      Cachy.key_versions[:xxx].should == 1
    end

    it "adds a string key as symbol" do
      Cachy.cache('yyy'){1}
      Cachy.key_versions[:yyy].should == 1
    end

    it "does not overwrite a key when it already exists" do
      Cachy.key_versions = {:xxx => 3}
      Cachy.cache(:xxx){1}
      Cachy.cache(:xxx){1}
      Cachy.key_versions[:xxx].should == 3
    end

    it "reloads when keys have expired" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>(Time.now.to_i - 60)}
      TEST_CACHE.write 'cachy_key_versions', {:xx=>1}
      Cachy.key_versions.should == {:xx=>1}
    end

    it "does not reload when keys have not expired" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>Time.now.to_i}
      TEST_CACHE.write 'cachy_key_versions', {:xx=>1}
      Cachy.key_versions.should == {:xx=>2}
    end

    it "expires when key_versions is set" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>Time.now.to_i}
      Cachy.key_versions = {:xx=>1}
      Cachy.key_versions[:xx].should == 1
    end
  end
end