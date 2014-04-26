# Better Errors [![Gem Version](http://img.shields.io/gem/v/better_errors.svg)](https://rubygems.org/gems/better_errors) [![Build Status](https://travis-ci.org/charliesome/better_errors.svg)](https://travis-ci.org/charliesome/better_errors) [![Code Climate](http://img.shields.io/codeclimate/github/charliesome/better_errors.svg)](https://codeclimate.com/github/charliesome/better_errors)

Better Errors replaces the standard Rails error page with a much better and more useful error page. It is also usable outside of Rails in any Rack app as Rack middleware.

![image](http://i.imgur.com/6zBGAAb.png)

## Features

* Full stack trace
* Source code inspection for all stack frames (with highlighting)
* Local and instance variable inspection
* Live REPL on every stack frame

## Installation

Add this to your Gemfile:

```ruby
group :development do
  gem "better_errors"
end
```

If you would like to use Better Errors' **advanced features** (REPL, local/instance variable inspection, pretty stack frame names), you need to add the [`binding_of_caller`](https://github.com/banister/binding_of_caller) gem by [@banisterfiend](http://twitter.com/banisterfiend) to your Gemfile:

```ruby
gem "binding_of_caller"
```

This is an optional dependency however, and Better Errors will work without it.

_Note: If you discover that Better Errors isn't working - particularly after upgrading from version 0.5.0 or less - be sure to set `config.consider_all_requests_local = true` in `config/environments/development.rb`._

## Security

**NOTE:** It is *critical* you put better\_errors in the **development** section. **Do NOT run better_errors in production, or on Internet facing hosts.**

You will notice that the only machine that gets the Better Errors page is localhost, which means you get the default error page if you are developing on a remote host (or a virtually remote host, such as a Vagrant box). Obviously, the REPL is not something you want to expose to the public, but there may also be other pieces of sensitive information available in the backtrace.

To poke selective holes in this security mechanism, you can add a line like this to your startup (for example, on Rails it would be `config/environments/development.rb`)

```ruby
BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']
```

Then run Rails like this:

```shell
TRUSTED_IP=66.68.96.220 rails s
```

Note that the `allow_ip!` is actually backed by a `Set`, so you can add more than one IP address or subnet.

**Tip:** You can find your apparent IP by hitting the old error page's "Show env dump" and looking at "REMOTE_ADDR".

**VirtualBox:** If you are using VirtualBox and are accessing the guest from your host's browser, you will need to use `allow_ip!` to see the error page.

## Usage

If you're using Rails, there's nothing else you need to do.

If you're not using Rails, you need to insert `BetterErrors::Middleware` into your middleware stack, and optionally set `BetterErrors.application_root` if you'd like Better Errors to abbreviate filenames within your application.

Here's an example using Sinatra:

```ruby
require "sinatra"
require "better_errors"

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

get "/" do
  raise "oops"
end
```

### Unicorn, Puma, and other multi-worker servers

Better Errors works by leaving a lot of context in server process memory. If
you're using a web server that runs multiple "workers" it's likely that a second
request (as happens when you click on a stack frame) will hit a different
worker. That worker won't have the necessary context in memory, and you'll see
a `Session Expired` message.

If this is the case for you, consider turning the number of workers to one (1)
in `development`. Another option would be to use Webrick, Mongrel, Thin,
or another single-process server as your `rails server`, when you are trying
to troubleshoot an issue in development.

## Get in touch!

If you're using better_errors, I'd love to hear from you. Drop me a line and tell me what you think!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
