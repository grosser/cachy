require 'spec/spec_helper'

describe Cachy do
  before do
    @cache = TestCache.new
    Cachy.cache_store = @cache
    Cachy.class_eval "@@key_versions = {:versions=>{}, :last_set=>0}"
    @cache.write(Cachy::HEALTH_CHECK_KEY, 'yes')
    Cachy.send(:class_variable_set, '@@cache_error', false)
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
  
  describe :cache_if do
    it "should not call the cache command if condition is wrong" do
      Cachy.should_not_receive(:cache)
      Cachy.cache_if(false, :x) do
        "asd"
      end
    end
    
    it "should call cache command if condition is true" do
      Cachy.should_receive(:cache)
      Cachy.cache_if(true, :x) do
        "asd"
      end
    end
    
    it "should pass params correctly" do
      Cachy.should_receive(:cache).with(:x, {:y => 1}, :expires_in => 3)
      Cachy.cache_if(true, :x, {:y => 1}, :expires_in => 3) do
        "asd"
      end
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

      @cache.keys.select{|k| k=~ /my_key/}.size.should == 4
      Cachy.stub!(:locales).and_return locales
      Cachy.expire(:my_key)
      @cache.keys.select{|k| k=~ /my_key/}.size.should == 0
    end

    it "does not expire other keys" do
      Cachy.cache(:another_key){ 'X' }
      Cachy.cache(:my_key){ 'X' }
      Cachy.cache(:yet_another_key){ 'X' }
      Cachy.expire :my_key
      @cache.keys.should include("another_key_v1")
      @cache.keys.should include("yet_another_key_v1")
    end

    it "expires the cache when no available_locales are set" do
      Cachy.cache(:another_key){ "X" }
      Cachy.cache(:my_key){ "X" }

      @cache.keys.select{|k| k=~ /my_key/}.size.should == 1
      Cachy.expire(:my_key)
      @cache.keys.select{|k| k=~ /my_key/}.size.should == 0
    end

    it "expires the cache with prefix" do
      key = 'views/my_key_v1'
      @cache.write(key, 'x')
      @cache.read(key).should_not == nil
      Cachy.expire(:my_key, :prefix=>'views/')
      @cache.read(key).should == nil
    end
  end

  describe :expire_view do
    it "expires the cache with prefix" do
      key = 'views/my_key_v1'
      @cache.write(key, 'x')
      @cache.read(key).should_not == nil
      Cachy.expire_view(:my_key)
      @cache.read(key).should == nil
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
      # a bit weird but just module I18n does not work with 1.9.1
      i18n = Module.new
      i18n.class_eval do
        def self.locale
          :de
        end
      end
      Object.const_set :I18n, i18n

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
      Cachy.key_versions = nil
      Cachy.key_versions.should == {}
    end

    it "merges in old when setting new" do
      pending '!!!!!'
    end

    it "adds a key when cache is called the first time" do
      Cachy.cache(:xxx){1}
      Cachy.key_versions[:xxx].should == 1
      @cache.read(Cachy::KEY_VERSIONS_KEY).should_not == nil
    end

    it "does not add a key when cache is called the first time and cache is not healthy" do
      @cache.write(Cachy::HEALTH_CHECK_KEY, 'no')
      Cachy.cache(:xxx){1}
      @cache.read(Cachy::KEY_VERSIONS_KEY).should == nil
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
      @cache.write Cachy::KEY_VERSIONS_KEY, {:xx=>1}
      Cachy.key_versions.should == {:xx=>1}
    end

    it "does not reload when keys have not expired" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>Time.now.to_i}
      @cache.write Cachy::KEY_VERSIONS_KEY, {:xx=>1}
      Cachy.key_versions.should == {:xx=>2}
    end

    it "expires when key_versions is set" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>Time.now.to_i}
      Cachy.key_versions = {:xx=>1}
      Cachy.key_versions[:xx].should == 1
    end
  end

  describe :key_versions, "with timeout" do
    before do
      @mock = mock = {}
      @cache.instance_eval{@data = mock}
      def @mock.read_error_occured
        false
      end
      def @mock.[](x)
        {:x => 1}
      end
      Cachy.send(:class_variable_set, '@@cache_error', false)
    end

    it "reads normally" do
      Cachy.send(:read_versions).should == {:x => 1}
    end

    it "reads empty when it crashes" do
      @mock.should_receive(:[]).and_return nil # e.g. Timout happended
      @mock.should_receive(:read_error_occured).and_return true
      Cachy.send(:read_versions).should == {}
    end

    it "marks as error when it crashes" do
      Cachy.send(:class_variable_get, '@@cache_error').should == false
      @mock.should_receive(:read_error_occured).and_return true
      Cachy.send(:read_versions)
      Cachy.send(:class_variable_get, '@@cache_error').should == true
    end

    it "marks as error free when it reads successfully" do
      Cachy.send(:class_variable_set, '@@cache_error', true)
      Cachy.send(:class_variable_get, '@@cache_error').should == true
      Cachy.send(:read_versions).should == {:x => 1}
      Cachy.send(:class_variable_get, '@@cache_error').should == false
    end

    it "writes when it was not error before" do
      Cachy.cache_store.should_receive(:write)
      Cachy.send(:write_version, {})
    end

    it "does not write when it was error before" do
      Cachy.send(:class_variable_set, '@@cache_error', true)
      Cachy.cache_store.should_not_receive(:write)
      Cachy.send(:write_version, {})
    end
  end

  describe :delete_key do
    it "removes a key from key versions" do
      Cachy.cache(:xxx){1}
      Cachy.key_versions.key?(:xxx).should == true
      Cachy.delete_key :xxx
      Cachy.key_versions.key?(:xxx).should == false
    end

    it "does not crash with unfound key" do
      Cachy.delete_key :xxx
      Cachy.delete_key :xxx
      Cachy.key_versions.key?(:xxx).should == false
    end
  end
end