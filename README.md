Prerender Rails [![Build Status](https://travis-ci.org/collectiveip/prerender_rails.png)](https://travis-ci.org/collectiveip/prerender_rails) [![Gem Version](https://badge.fury.io/rb/prerender_rails.png)](http://badge.fury.io/rb/prerender_rails)
=========================== 

Google, Facebook, Twitter, Yahoo, and Bing are constantly trying to view your website... but they don't execute javascript. That's why we built Prerender. Prerender is perfect for AngularJS SEO, BackboneJS SEO, EmberJS SEO, and any other javascript framework.

This middleware intercepts requests to your Rails website from crawlers, and then makes a call to the (external) Prerender Service to get the static HTML instead of the javascript for that page.

Prerender adheres to google's `_escaped_fragment_` proposal, which we recommend you use. It's easy:
- Just add &lt;meta name="fragment" content="!"> to the &lt;head> of all of your pages
- If you use hash urls (#), change them to the hash-bang (#!)
- That's it! Perfect SEO on javascript pages.

`Note` Make sure you have more than one webserver thread/process running because the prerender service will make a request to your server to render the HTML.

Add this line to your application's Gemfile:

    gem 'prerender_rails'

And in `config/environment/production.rb`, add this line:

```ruby
	config.middleware.use Rack::Prerender
```

or if you have an account on [prerender.io](http://prerender.io) and want to use your token:

```ruby
	config.middleware.use Rack::Prerender, prerender_token: 'YOUR_TOKEN'
```

`Note` If you're testing locally, you'll need to run the [prerender server](https://github.com/collectiveip/prerender) locally so that it has access to your server.

## Testing

If your URLs use a hash-bang:

	If you want to see `http://localhost:5000/#!/profiles/1234`
	Then go to `http://localhost:5000/?_escaped_fragment_=/profiles/1234`

If your URLs use push-state:

	If you want to see `http://localhost:5000/profiles/1234`
	Then go to `http://localhost:5000/profiles/1234?_escaped_fragment_=`

## How it works
1. The middleware checks to make sure we should show a prerendered page
	1. The middleware checks if the request is from a crawler (`_escaped_fragment_` or agent string)
	2. The middleware checks to make sure we aren't requesting a resource (js, css, etc...)
	3. (optional) The middleware checks to make sure the url is in the whitelist
	4. (optional) The middleware checks to make sure the url isn't in the blacklist
2. The middleware makes a `GET` request to the [prerender service](https://github.com/collectiveip/prerender)(phantomjs server) for the page's prerendered HTML
3. Return that HTML to the crawler

# Customization

### Whitelist

Whitelist a single url path or multiple url paths. Compares using regex, so be specific when possible. If a whitelist is supplied, only url's containing a whitelist path will be prerendered.
```ruby
config.middleware.use Rack::Prerender, whitelist: '^/search'
```
```ruby
config.middleware.use Rack::Prerender, whitelist: ['/search', '/users/.*/profile']
```

### Blacklist

Blacklist a single url path or multiple url paths. Compares using regex, so be specific when possible. If a blacklist is supplied, all url's will be prerendered except ones containing a blacklist path.
```ruby
config.middleware.use Rack::Prerender, blacklist: '^/search'
```
```ruby
config.middleware.use Rack::Prerender, blacklist: ['/search', '/users/.*/profile']
```

### before_render

This method is intended to be used for caching, but could be used to save analytics or anything else you need to do for each crawler request. If you return a string from before_render, the middleware will serve that to the crawler instead of making a request to the prerender service.
```ruby
config.middleware.use Rack::Prerender,
	before_render: (Proc.new do |env|
		# do whatever you need to do.
	end)
```

### after_render

This method is intended to be used for caching, but could be used to save analytics or anything else you need to do for each crawler request. This method is a noop and is called after the prerender service returns HTML.
```ruby
config.middleware.use Rack::Prerender,
	after_render: (Proc.new do |env, response|
		# do whatever you need to do.
	end)
```

### build_rack_response_from_prerender

This method is intended to be used to modify the response before it is sent to the crawler. Use this method to add/remove response headers, or do anything else before the request is sent.
```ruby
config.middleware.use Rack::Prerender,
	build_rack_response_from_prerender: (Proc.new do |response, prerender_response|
		# response is already populated with the prerender status code, html, and headers
		# prerender_response is the response that came back from the prerender service
	end)
```

## Caching

This rails middleware is ready to be used with [redis](http://redis.io/) or [memcached](http://memcached.org/) to return prerendered pages in milliseconds.

When setting up the middleware in `config/environment/production.rb`, you can add a `before_render` method and `after_render` method for caching.

Here's an example testing a local redis cache:

_Put this in `config/environment/development.rb`, and add `gem 'redis'` to your Gemfile._

```ruby
require 'redis'
@redis = Redis.new
config.middleware.use Rack::Prerender,
  before_render: (Proc.new do |env|
    @redis.get(Rack::Request.new(env).url)
  end),
  after_render: (Proc.new do |env, response|
    @redis.set(Rack::Request.new(env).url, response.body)
  end)
```

## Using your own prerender service

We host a Prerender server at [prerender.io](http://prerender.io) so that you can work on more important things, but if you've deployed the prerender service on your own... set the `PRERENDER_SERVICE_URL` environment variable so that this middleware points there instead. Otherwise, it will default to the service already deployed by [prerender.io](http://prerender.io).

	$ export PRERENDER_SERVICE_URL=<new url>

Or on heroku:

	$ heroku config:add PRERENDER_SERVICE_URL=<new url>

As an alternative, you can pass `prerender_service_url` in the options object during initialization of the middleware

``` ruby
config.middleware.use Rack::Prerender, prerender_service_url: '&lt;new url>'
```

## License

The MIT License (MIT)

Copyright (c) 2013 Todd Hooper &lt;todd@collectiveip.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.