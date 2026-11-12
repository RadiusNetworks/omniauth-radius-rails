# frozen_string_literal: true

require 'rails_helper'

module Kracken
  module JsonApi
    RSpec.describe PublicExceptions do
      # `JsonApi.paths` is global state accumulated by the routing mapper, so
      # register a path for the example and put it back afterwards.
      around do |example|
        original = JsonApi.paths.dup
        JsonApi.add_path("/api")
        begin
          example.run
        ensure
          JsonApi.paths.replace(original)
        end
      end

      def env_for(path)
        Rack::MockRequest.env_for("http://app.example.com#{path}")
      end

      def call(path, app)
        described_class.new(app).call(env_for(path))
      end

      # The upstream response headers Rails itself would produce. Under Rack 3
      # these are lower-cased, so build them the way Rails does rather than
      # hard-coding a spelling.
      def rack_headers(pairs = {})
        headers = ActionDispatch::Response::Headers.new
        pairs.each { |k, v| headers[k] = v }
        headers
      end

      describe "paths it does not handle" do
        it "passes the response through untouched" do
          app = ->(_env) { [200, rack_headers('Content-Type' => 'text/html'), ['hi']] }

          status, _headers, body = call("/pages/1", app)

          expect(status).to eq 200
          expect(body).to eq ['hi']
        end

        it "does not convert an upstream cascade into an error document" do
          app = ->(_env) { [404, rack_headers('X-Cascade' => 'pass'), []] }

          status, _headers, _body = call("/pages/1", app)

          expect(status).to eq 404
        end
      end

      describe "a cascading (unrouted) JSON API request" do
        # Regression guard: Rails spells this header "x-cascade" under Rack 3
        # and "X-Cascade" under Rack 2. Matching one spelling literally made
        # this silently stop working, returning the bare upstream 404 instead
        # of a JSON API error document.
        let(:app) { ->(_env) { [404, rack_headers('X-Cascade' => 'pass'), []] } }

        it "renders a JSON API error document" do
          status, _headers, body = call("/api/widgets", app)

          expect(status).to eq 404
          expect(JSON.parse(body.first)["errors"].first)
            .to include("status" => "404", "title" => "Not Found")
        end

        it "sets a JSON content type that is readable in either Rack's casing" do
          _status, headers, body = call("/api/widgets", app)
          charset = ActionDispatch::Response.default_charset

          # Looked up both ways on purpose: Rack 2 and Rack 3 disagree on the
          # canonical casing, so the value has to be reachable either way.
          expect(headers['Content-Type']).to eq "application/json; charset=#{charset}"
          expect(headers['content-type']).to eq "application/json; charset=#{charset}"
          expect(headers['Content-Length']).to eq body.first.bytesize.to_s
        end
      end

      describe "an exception raised on a JSON API path" do
        it "maps a known Kracken error to its status and detail" do
          app = ->(_env) { raise TokenUnauthorized, "nope" }

          status, _headers, body = call("/api/widgets", app)
          error = JSON.parse(body.first)["errors"].first

          expect(status).to eq 401
          expect(error).to include("status" => "401", "detail" => "nope")
        end

        it "maps UnprocessableEntity to 422 without a Rack deprecation warning" do
          app = ->(_env) { raise UnprocessableEntity, "bad" }

          # Rack warns via `Kernel#warn` from inside `Rack::Utils`, so watch
          # stderr rather than stubbing a receiver. Give the middleware its own
          # logger so its error log doesn't land on stderr too.
          env = env_for("/api/widgets")
          env['action_dispatch.logger'] = ActiveSupport::Logger.new(StringIO.new)

          status = nil
          expect {
            status, _headers, _body = described_class.new(app).call(env)
          }.not_to output.to_stderr

          expect(status).to eq 422
        end

        it "reports an unmapped error as a 500" do
          app = ->(_env) { raise "boom" }

          status, _headers, _body = call("/api/widgets", app)

          expect(status).to eq 500
        end
      end
    end
  end
end
