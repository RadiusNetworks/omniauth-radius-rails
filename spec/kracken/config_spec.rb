require 'spec_helper'

module Kracken
  describe Config do

    subject(:config){ Kracken::Config.new }

    it "sets a default url" do
      expect(config.url).to eq "https://account.messageradius.com"
    end

    it "sets the url" do
      config.provider_url = "http://joe.com"

      expect(config.url).to eq "http://joe.com"
    end

  end
end
