require 'spec_helper'

module Kracken
  RSpec.describe Config do

    subject(:config){ Kracken::Config.new }

    it "sets a default url" do
      expect(config.provider_url).to eq "https://account.radiusnetworks.com"
    end

    it "sets a default user class" do
      stub_const "User", "user class"
      expect(config.user_class).to eq "user class"
    end

    it "sets the url" do
      config.provider_url = "http://joe.com"

      expect(config.provider_url).to eq "http://joe.com"
    end

  end
end
