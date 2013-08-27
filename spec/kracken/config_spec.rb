require 'spec_helper'

module Kracken
describe Config do

  it "sets a default url" do
    config = Kracken::Config.new
    expect(config.url).to eq "https://account.messageradius.com"
  end

end
end
