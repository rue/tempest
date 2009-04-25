require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper.rb"))

# Our stuff
require "waves/foundations/rest"

include Waves::Foundations

describe "Defining an Application" do
  before :all do
    module AppDefModule; end
  end

  after :all do
    Object.send :remove_const, :AppDefModule
  end

  after :each do
    Waves.applications.clear
    AppDefModule.send :remove_const, :DefSpecApp if AppDefModule.const_defined?(:DefSpecApp)
    Object.send :remove_const, :DefSpecApp if Object.const_defined?(:DefSpecApp)
  end

  # @todo Much fleshing out here. Overrides and such. --rue

  it "is created as a class by given name under the nesting module" do
    AppDefModule.const_defined?(:DefSpecApp).should == false

    module AppDefModule
      application(:DefSpecApp) {
        composed_of { at [true], "hi" => :Hi }
      }
    end

    AppDefModule.const_defined?(:DefSpecApp).should == true
    Object.const_defined?(:DefSpecApp).should == false
  end

  it "is created as a class by given name under Object if not nested" do
    Object.const_defined?(:DefSpecApp).should == false

    application(:DefSpecApp) {
      composed_of { at [true], "hi" => :Hi }
    }

    Object.const_defined?(:DefSpecApp).should == true
  end

  it "raises an error unless some resource composition is done" do
    lambda {
      application(:DefSpecApp) {
      }
    }.should raise_error(REST::BadDefinition)

    lambda {
      application(:DefSpecApp) {
        composed_of {}
      }
    }.should raise_error(REST::BadDefinition)
  end

  it "adds the Application to the application list" do
    Waves.applications.should be_empty

    myapp = Object.new
    application(:DefSpecApp) {
      myapp = self
      composed_of { at [true], "hi" => :Hi }
    }

    Waves.applications.size.should == 1
    Waves.main.should == myapp
  end
end


describe "Composing resources in the Application definition" do
  after :each do
    Waves.applications.clear
    Object.send :remove_const, :DefSpecApp if Object.const_defined?(:DefSpecApp)
  end

  it "uses the .at method to map mount points to filenames, aliased to a name" do
    application(:DefSpecApp) {
      composed_of {
        at ["foobar"], "page" => :page
      }
    }

    resources = Waves.main.resources
    resources.size.should == 1
    resources[:page].file.should == "page"
    resources[:page].mountpoint.should == ["foobar"]
  end

  it "stores the name as a lowercase symbol" do
    application(:DefSpecApp) {
      composed_of {
        at ["foobar2"], "page2" => :Page
      }
    }

    resources = Waves.main.resources
    resources[:page].file.should == "page2"
    resources[:page].mountpoint.should == ["foobar2"]
  end

  # @todo I am a bit iffy about the concept of a "main resource". --rue
  it "defines a Mounts resource as the root" do
    application(:DefSpecApp) {
      composed_of {
        at ["foobar"], "page" => :Page
      }
    }

    DefSpecApp.const_defined?(:Mounts).should == true
  end

  # @todo This needs a functional counterpart to actually verify the call. --rue
  it "defines matchers for a composing resource using its mount point" do
    mock(Waves::Resources::Base).on(true, ["foobar"])

    application(:DefSpecApp) {
      composed_of {
        at ["foobar"], "pg" => :Page
      }
    }
  end

  # @todo Do we need to assert the negative here too? --rue
  it "defines matchers for all composing resources in order of appearance" do
    sequence = [["foobar"],
                [true],
                ["meebies"],
                [],
                ["ugga"]
               ]

    mock(Waves::Resources::Base).on(true,
                                    satisfy {|path|
                                      path == sequence.shift
                                    }
                                   ).times(sequence.size)

    application(:DefSpecApp) {
      composed_of {
        at ["foobar"], "pg" => :Page
        at [true], "me" => :whatever
        at ["meebies"], "bleh" => "yay"
        at [], "weird" => :evenStranger
        at ["ugga"], "meh/beh" => :Alt
      }
    }
  end
end

describe "An Application supporting a resource" do
  before :each do
    application(:DefSpecApp) {
      composed_of {
        at ["foobar", :something], "pg" => :DefSpecRes
      }
    }
  end

  after :each do
    Waves.applications.clear
    Object.send :remove_const, :DefSpecApp if Object.const_defined?(:DefSpecApp)
  end

  it "provides it a full pathspec given the resource-specific part using .url_for" do
    resource(:DefSpecRes) {
      url_of_form [{:path => 0..-1}, :name]
      viewable { representation("text/html") {} }
    }

    pathspec = Waves.main.url_for(DefSpecRes, [{:path => 0..-1}, :name])
    pathspec.should == ["foobar", :something, {:path => 0..-1}, :name]
  end

end

