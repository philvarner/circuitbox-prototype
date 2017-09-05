require 'faraday'
require 'circuitbox/faraday_middleware'

class WelcomeController < ApplicationController

  def index
    start = Time.now
    faraday = faraday_with_default_adapter('https://localhost:26443', :github)
    # faraday = faraday_with_default_adapter('https://localhost:26443', :github, {api_token: 'xyz', api_token_secret: 'xyz'})
    @response = faraday.get '/showcases/game-off-winners'
    @elapsed = Time.now - start
  end

  def faraday_with_default_adapter(base, identifier, query_params = {},
                                   open_timeout = 5,
                                   read_timeout = 15)
    cb_options = { timeout_seconds: 20,
                   sleep_window: 30,
                   time_window: 60,
                   volume_threshold: 10,
                   error_threshold: 10 }

    Faraday.new(base,
                ssl: { verify: false },
                request: { open_timeout: open_timeout, timeout: read_timeout },
                params: query_params) do |conn|
      conn.use FaradayMiddleware::FollowRedirects, limit: 5
      conn.use Circuitbox::FaradayMiddleware,
               identifier: identifier,
               circuit_breaker_options: cb_options,
               # Timeout::Error must be here or won't actually do a timeout
               exceptions: [Timeout::Error, Faraday::ConnectionFailed, Faraday::TimeoutError,
                            Circuitbox::FaradayMiddleware::RequestFailed]

      yield conn if block_given?

      # IMPORTANT Without this line, nothing will happen.
      conn.adapter Faraday.default_adapter
    end
  end
end
