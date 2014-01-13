module Rack
  class Prerender
    require 'net/http'

    def initialize(app, options={})

      # USED TO KEEP TRACK OF THE CURRENT PRERENDER SERVICE USED
      @current_prerender_service_index = 0

      @crawler_user_agents = [
        'googlebot',
        'yahoo',
        'bingbot',
        'baiduspider',
        'facebookexternalhit',
        'twitterbot'
      ]

      @extensions_to_ignore = [
        '.js',
        '.css',
        '.xml',
        '.less',
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.pdf',
        '.doc',
        '.txt',
        '.ico',
        '.rss',
        '.zip',
        '.mp3',
        '.rar',
        '.exe',
        '.wmv',
        '.doc',
        '.avi',
        '.ppt',
        '.mpg',
        '.mpeg',
        '.tif',
        '.wav',
        '.mov',
        '.psd',
        '.ai',
        '.xls',
        '.mp4',
        '.m4a',
        '.swf',
        '.dat',
        '.dmg',
        '.iso',
        '.flv',
        '.m4v',
        '.torrent'
      ]

      @options = options
      @options[:whitelist] = [@options[:whitelist]] if @options[:whitelist].is_a? String
      @options[:blacklist] = [@options[:blacklist]] if @options[:blacklist].is_a? String
      @extensions_to_ignore = @options[:extensions_to_ignore] if @options[:extensions_to_ignore]
      @crawler_user_agents = @options[:crawler_user_agents] if @options[:crawler_user_agents]
      @app = app
    end


    def call(env)
      if should_show_prerendered_page(env)

        cached_response = before_render(env)

        if cached_response
          return cached_response.finish
        end

        prerendered_response = get_prerendered_page_response(env)

        if prerendered_response
          response = build_rack_response_from_prerender(prerendered_response)
          after_render(env, prerendered_response)
          return response.finish
        end
      end

      @app.call(env)  
    end


    def should_show_prerendered_page(env)
      user_agent = env['HTTP_USER_AGENT']
      return false if !user_agent
      return false if env['REQUEST_METHOD'] != 'GET'

      request = Rack::Request.new(env)

      # if it is requesting with an _escaped_fragment_
      return true if Rack::Utils.parse_query(request.query_string).has_key?('_escaped_fragment_')

      #if it is not a bot...dont prerender
      return false if @crawler_user_agents.all? { |crawler_user_agent| !user_agent.downcase.include?(crawler_user_agent.downcase) }

      #if it is a bot and is requesting a resource...dont prerender
      return false if @extensions_to_ignore.any? { |extension| request.path.include? extension }

      #if it is a bot and not requesting a resource and is not whitelisted...dont prerender
      return false if @options[:whitelist].is_a?(Array) && @options[:whitelist].all? { |whitelisted| !Regexp.new(whitelisted).match(request.path) }

      #if it is a bot and not requesting a resource and is not blacklisted(url or referer)...dont prerender
      if @options[:blacklist].is_a?(Array) && @options[:blacklist].any? { |blacklisted|
          blacklistedUrl = false
          blacklistedReferer = false
          regex = Regexp.new(blacklisted)

          blacklistedUrl = !!regex.match(request.path)
          blacklistedReferer = !!regex.match(request.referer) if request.referer

          blacklistedUrl || blacklistedReferer
        }
        return false
      end 

      return true
    end


    def get_prerendered_page_response(env)
      begin
        url = URI.parse(build_api_url(env))
        headers = { 'User-Agent' => env['HTTP_USER_AGENT'] }
        headers['X-Prerender-Token'] = ENV['PRERENDER_TOKEN'] if ENV['PRERENDER_TOKEN']
        headers['X-Prerender-Token'] = @options[:prerender_token] if @options[:prerender_token]
        req = Net::HTTP::Get.new(url.request_uri, headers)
        response = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
      rescue Exception => e
        Rails.logger.info("PrerenderRails: Error in get_prerendered_page_response function: ")
        Rails.logger.info(e.message)
        nil
      end
    end


    def build_api_url(env)
      new_env = env
      if env["CF-VISITOR"]
        match = /"scheme":"(http|https)"/.match(env['CF-VISITOR'])
        new_env["HTTPS"] = true and new_env["rack.url_scheme"] = "https" and new_env["SERVER_PORT"] = 443 if (match && match[1] == "https")
        new_env["HTTPS"] = false and new_env["rack.url_scheme"] = "http" and new_env["SERVER_PORT"] = 80 if (match && match[1] == "http")
      end

      url = Rack::Request.new(new_env).url
      prerender_url = get_prerender_service_url()
      forward_slash = prerender_url[-1, 1] == '/' ? '' : '/'
      "#{prerender_url}#{forward_slash}#{url}"
    end


    # THIS METHOD IS USED TO RETRIEVE THE URL OF THE PRERENDER SERVICE
    # Default is: http://prerender.herokuapp.com/
    # You can set it in your app: 
    #   config.middleware.use Rack::Prerender, :prerender_service_url => 'http://myserviceurlhere:port' # in your environment.rb file
    # or in your shell: 
    #   export PRERENDER_SERVICE_URL=http://myserviceurlhere:port # in your environment variables
    def get_prerender_service_url

      # assuming that the url is a string
      url = @options[:prerender_service_url] || ENV['PRERENDER_SERVICE_URL'] || 'http://prerender.herokuapp.com/'
      
      # maybe it is an array. is it?
      if url.kind_of? Array

        # get the total length of the array
        length = url.length

        # check that the saved index is lower than the array itself. the set it to 0 if it is.
        @current_prerender_service_index = 0 if @current_prerender_service_index >= length

        # get the url is now taken from the array and right into the returned variable
        url = url[@current_prerender_service_index]

        # increment the index for the next time you will call this method
        @current_prerender_service_index += 1
      end

      url

    end


    def build_rack_response_from_prerender(prerendered_response)
      response = Rack::Response.new(prerendered_response.body, prerendered_response.code, prerendered_response.header)

      @options[:build_rack_response_from_prerender].call(response, prerendered_response) if @options[:build_rack_response_from_prerender]

      response
    end


    def before_render(env)
      return nil unless @options[:before_render]

      cached_render = @options[:before_render].call(env)
      
      if cached_render && cached_render.is_a?(String)
        Rack::Response.new(cached_render, 200, [])
      elsif cached_render && cached_render.is_a?(Rack::Response)
        cached_render
      else
        nil
      end
    end


    def after_render(env, response)
      return true unless @options[:after_render]
      @options[:after_render].call(env, response)
    end
  end
end
