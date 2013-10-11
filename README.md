Prerender Rails [![Build Status](https://travis-ci.org/collectiveip/prerender_rails.png)](https://travis-ci.org/collectiveip/prerender_rails)
=========================== 

Are you using backbone, angular, emberjs, etc, but you're unsure about the SEO implications?

Use this gem to install rails middleware that prerenders a javascript-rendered page using an external service and returns the HTML to the search engine crawler for SEO.

`Note:` Make sure you have more than one webserver thread/process running because the prerender service will make a request to your server to render the HTML.

Add this line to your application's Gemfile:

    gem 'prerender_rails'

And in `config/environment/production.rb`, add this line:

```ruby
	config.middleware.use Rack::Prerender
```

## How it works
1. Check to make sure we should show a prerendered page
	1. Check if the request is from a crawler (agent string)
	2. Check to make sure we aren't requesting a resource (js, css, etc...)
	3. (optional) Check to make sure the url is in the whitelist
	4. (optional) Check to make sure the url isn't in the blacklist
2. Make a `GET` request to the [prerender service](https://github.com/collectiveip/prerender)(phantomjs server) for the page's prerendered HTML
3. Return that HTML to the crawler

## Customization

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

### Using your own prerender service

If you've deployed the prerender service on your own, set the `PRERENDER_SERVICE_URL` environment variable so that this package points there instead. Otherwise, it will default to the service already deployed at `http://prerender.herokuapp.com`

	$ export PRERENDER_SERVICE_URL=<new url>

As an alternative, you can pass `prerender_service_url` in the options object during initialization of the middleware

``` ruby
config.middleware.use Rack::Prerender, prerender_service_url: '<new url>'
```

## Testing

If you want to make sure your pages are rendering correctly:

1. Open the Developer Tools in Chrome (Cmd + Atl + J)
2. Click the Settings gear in the bottom right corner.
3. Click "Overrides" on the left side of the settings panel.
4. Check the "User Agent" checkbox.
6. Choose "Other..." from the User Agent dropdown.
7. Type `googlebot` into the input box.
8. Refresh the page (make sure to keep the developer tools open).

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