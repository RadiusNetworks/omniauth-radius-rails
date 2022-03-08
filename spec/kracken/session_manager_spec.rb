# frozen_string_literal: true

require 'rails_helper'

module Kracken
  RSpec.describe SessionManager do
    include Kracken::Spec::UsingEnv

    describe "::conn" do
      before { SessionManager.reset_conn }

      context "when the REDIS_SESSION_URL env var is present" do
        it 'is a Redis instance' do
          using_env({ "REDIS_SESSION_URL" => "redis://www.example.com" }) do
            expect(SessionManager.conn).to be_an_instance_of Redis
          end
        end
      end

      context "when the REDIS_SESSION_URL env var is not present" do
        it 'is a NullRedis instance' do
          expect(SessionManager.conn).to be_an_instance_of SessionManager::NullRedis
        end
      end
    end
  end
end
