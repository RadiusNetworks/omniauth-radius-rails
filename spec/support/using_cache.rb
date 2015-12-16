RSpec.shared_context "using Rails cache", :using_cache do
  before(:context) do
    @org_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
  end

  after(:context) do
    Rails.cache = @org_cache
  end

  before do
    Rails.cache.clear
  end
end
