require_relative '../test_helper'
 
describe Rack::Prerender do

  bot = 'googlebot'
  user = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.76 Safari/537.36'

  before :each do
    @app = lambda do |params|
      [200, {}, ""]
    end

    @prerender = Rack::Prerender.new(@app)
  end

  it "should return a prerendered reponse for a crawler" do
    request = Rack::MockRequest.env_for "/", "HTTP_USER_AGENT" => bot
    stub_request(:get, @prerender.build_api_url(request)).to_return(:body => "<html></html>")
    response = Rack::Prerender.new(@app).call(request)

    assert_equal response[2].body, ["<html></html>"]
  end

  it "should continue to app routes if user is not a bot by checking agent string" do
    request = Rack::MockRequest.env_for "/", "HTTP_USER_AGENT" => user
    response = Rack::Prerender.new(@app).call(request)

    assert_equal response[2], ""
  end

  it "should continue to app routes if user is a bot, but the bot is requesting a resource file" do
    request = Rack::MockRequest.env_for "/main.js?anyQueryParam=true", "HTTP_USER_AGENT" => bot
    response = Rack::Prerender.new(@app).call(request)

    assert_equal response[2], ""
  end

  it "should continue to app routes if the url is not part of the whitelist" do
    request = Rack::MockRequest.env_for "/profile/blah", "HTTP_USER_AGENT" => bot
    response = Rack::Prerender.new(@app, whitelist: ['/search', '/help']).call(request)

    assert_equal response[2], ""
  end

  it "should continue to app routes if the url is not part of the regex specific whitelist" do
    request = Rack::MockRequest.env_for "/saved/search/blah", "HTTP_USER_AGENT" => bot
    response = Rack::Prerender.new(@app, whitelist: ['^/search', '/help']).call(request)

    assert_equal response[2], ""
  end

  it "should return a prerendered response if the url is part of the whitelist" do
    request = Rack::MockRequest.env_for "/search/things/123/page", "HTTP_USER_AGENT" => bot
    stub_request(:get, @prerender.build_api_url(request)).to_return(:body => "<html></html>")
    response = Rack::Prerender.new(@app, whitelist: ['/search', '/help']).call(request)

    assert_equal response[2].body, ["<html></html>"]
  end

  it "should return a prerendered response if the url is part of the regex specific whitelist" do
    request = Rack::MockRequest.env_for "/search/things/123/page", "HTTP_USER_AGENT" => bot
    stub_request(:get, @prerender.build_api_url(request)).to_return(:body => "<html></html>")
    response = Rack::Prerender.new(@app, whitelist: ['^/search.*page', '/help']).call(request)

    assert_equal response[2].body, ["<html></html>"]
  end

  it "should continue to app routes if the url is part of the blacklist" do
    request = Rack::MockRequest.env_for "/search/things/123/page", "HTTP_USER_AGENT" => bot
    response = Rack::Prerender.new(@app, blacklist: ['/search', '/help']).call(request)

    assert_equal response[2], ""
  end

  it "should continue to app routes if the url is part of the regex specific blacklist" do
    request = Rack::MockRequest.env_for "/search/things/123/page", "HTTP_USER_AGENT" => bot
    response = Rack::Prerender.new(@app, blacklist: ['^/search', '/help']).call(request)

    assert_equal response[2], ""
  end

  it "should return a prerendered response if the url is not part of the blacklist" do
    request = Rack::MockRequest.env_for "/profile/blah", "HTTP_USER_AGENT" => bot
    stub_request(:get, @prerender.build_api_url(request)).to_return(:body => "<html></html>")
    response = Rack::Prerender.new(@app, blacklist: ['/search', '/help']).call(request)

    assert_equal response[2].body, ["<html></html>"]
  end

  it "should return a prerendered response if the url is not part of the regex specific blacklist" do
    request = Rack::MockRequest.env_for "/profile/search/blah", "HTTP_USER_AGENT" => bot
    stub_request(:get, @prerender.build_api_url(request)).to_return(:body => "<html></html>")
    response = Rack::Prerender.new(@app, blacklist: ['^/search', '/help']).call(request)

    assert_equal response[2].body, ["<html></html>"]
  end

  it "should continue to app routes if the referer is part of the blacklist" do
    request = Rack::MockRequest.env_for "/api/results", "HTTP_USER_AGENT" => bot, "HTTP_REFERER" => '/search'
    response = Rack::Prerender.new(@app, blacklist: ['/search', '/help']).call(request)

    assert_equal response[2], ""
  end

  it "should continue to app routes if the referer is part of the regex specific blacklist" do
    request = Rack::MockRequest.env_for "/api/results", "HTTP_USER_AGENT" => bot, "HTTP_REFERER" => '/search'
    response = Rack::Prerender.new(@app, blacklist: ['^/search', '/help']).call(request)

    assert_equal response[2], ""
  end

  it "should return a prerendered response if the referer is not part of the blacklist" do
    request = Rack::MockRequest.env_for "/api/results", "HTTP_USER_AGENT" => bot, "HTTP_REFERER" => '/search'
    stub_request(:get, @prerender.build_api_url(request)).to_return(:body => "<html></html>")
    response = Rack::Prerender.new(@app, blacklist: ['/profile', '/help']).call(request)

    assert_equal response[2].body, ["<html></html>"]
  end

  it "should return a prerendered response if the referer is not part of the regex specific blacklist" do
    request = Rack::MockRequest.env_for "/api/results", "HTTP_USER_AGENT" => bot, "HTTP_REFERER" => '/profile/search'
    stub_request(:get, @prerender.build_api_url(request)).to_return(:body => "<html></html>")
    response = Rack::Prerender.new(@app, blacklist: ['^/search', '/help']).call(request)

    assert_equal response[2].body, ["<html></html>"]
  end
 
  describe '#buildApiUrl' do
    it "should build the correct api url with the default url" do
      request = Rack::MockRequest.env_for "https://google.com/search?q=javascript"
      assert_equal @prerender.build_api_url(request), 'http://prerender.herokuapp.com/https://google.com/search?q=javascript'
    end

    it "should build the correct api url with an environment variable url" do
      ENV['PRERENDER_SERVICE_URL'] = 'http://prerenderurl.com'
      request = Rack::MockRequest.env_for "https://google.com/search?q=javascript"
      assert_equal @prerender.build_api_url(request), 'http://prerenderurl.com/https://google.com/search?q=javascript'
      ENV['PRERENDER_SERVICE_URL'] = nil
    end
  end

end