# frozen_string_literal: true

module Kracken
  module Spec
    module UsingEnv
      # By forcing the use of a block, this makes working within the context of
      # a single spec much easier. If this needs to be wrapped around multiple
      # specs, then an appropriate #around(:example) hook may be used.
      #
      # This is stolen with love from https://github.com/RadiusNetworks/captain/blob/master/spec/support/using_env.rb
      #
      # @param env_stubs [Hash{String => Object}]
      #
      # @yieldreturn
      def using_env(env_stubs) # rubocop:disable Metrics/MethodLength
        keys_to_delete = env_stubs.keys - ENV.keys
        original_values = env_stubs.each_with_object({}) { |(k, v), env|
          env[k] = ENV[k] if ENV.key?(k)
          ENV[k] = v
        }
        yield
      ensure
        keys_to_delete.each do |k|
          ENV.delete(k)
        end
        original_values.each do |k, v|
          ENV[k] = v
        end
      end
    end
  end
end
