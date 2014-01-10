require 'spec_helper'

describe Edicy::Dtk do

  describe "#read_config" do

    context "when a config file is provided" do

      let(:config) { Edicy::Dtk.read_config 'spec/fixtures/.edicy' }
      
      it "api_token should be exactly as configured" do 
        config[:api_token].should eq("afcf30182aecfc8155d390d7d4552d14") 
      end

      it "site_url should be exactly as configured" do 
        config[:site_url].should eq("edicy.local") 
      end

    end

    context "when the provided filename is empty" do
      
      let(:config) { Edicy::Dtk.read_config "" }

      it "api_token should be nil" do 
        config[:api_token].should eq(nil) 
      end

      it "site_url should be nil" do 
        config[:site_url].should eq(nil) 
      end

    end

    context "when a filename is not provided" do
      
      let(:config) { Edicy::Dtk.read_config }

      it "api_token should be nil" do 
        config[:api_token].should eq(nil) 
      end

      it "site_url should be nil" do 
        config[:site_url].should eq(nil) 
      end

    end
  end  
end
