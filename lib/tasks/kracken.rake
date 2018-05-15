# frozen_string_literal: true

namespace :kracken do
  namespace :sweep do
    desc "Remove expired credentials after threshold days " \
         "(default threshold is 90 days)"
    task :credentials, %i[threshold] => :environment do |_t, args|
      threshold = args.fetch(:threshold) { 90 }.to_i
      timestamp = threshold.days.ago
      Rails.logger.info "Clearing expired `Credentials` older than " \
                        "#{threshold.days.inspect} (#{timestamp})"
      expired = Credentials.where(expires: true)
                           .where("expires_at < ?", timestamp)
                           .destroy_all
                           .size
      Rails.logger.info "Removed: #{expired} credentials"
      threshold *= 2
      timestamp = threshold.days.ago
      Rails.logger.info "Clearing legacy `Credentials` older than " \
                        "#{threshold.days.inspect} (#{timestamp})"
      legacy = Credentials.where(expires: [nil, false])
                          .where("updated_at < ?", timestamp)
                          .destroy_all
                          .size
      Rails.logger.info "Removed: #{legacy} credentials"
    end
  end
end
