require "rack/version"

module Rack
  class Prerender
    require 'net/http'

    def initialize(app)
      @app = app
    end

    def call(env)

      if should_show_prerendered_page(env)
        prerendered_response = get_prerendered_page_response(env)

        if prerendered_response && prerendered_response.is_a?(Net::HTTPSuccess)
          response = Rack::Response.new(prerendered_response.body, 200, [])
          return response.finish
        end
      end

      @app.call(env)  
    end

    def should_show_prerendered_page(env)
      request = Rack::Request.new(env)
      user_agent = env['HTTP_USER_AGENT'].downcase

      should_show_based_on_agent_string = user_agent == 'googlebot' ||
                        user_agent == 'yahoo' ||
                        user_agent == 'bingbot' ||
                        user_agent == 'baiduspider'

      return false if !should_show_based_on_agent_string #short circuit

      should_show_based_on_extension =  !request.path.include?('.js') &&
                        !request.path.include?('.css') &&
                        !request.path.include?('.less') &&
                        !request.path.include?('.png') &&
                        !request.path.include?('.jpg') &&
                        !request.path.include?('.jpeg') &&
                        !request.path.include?('.gif')

      should_show_based_on_agent_string && should_show_based_on_extension
    end

    def get_prerendered_page_response(env)
      begin
        url = Rack::Request.new(env).url
        prerender_url = ENV['PRERENDER_URL'] || 'http://prerender.herokuapp.com/'
        forward_slash = prerender_url[-1, 1] == '/' ? '' : '/'
        Net::HTTP.get_response(URI.parse("#{prerender_url}#{forward_slash}#{url}"))
      rescue
        nil
      end
    end
  end
end
