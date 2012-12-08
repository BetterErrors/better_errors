# Better Errors

Better Errors replaces the standard Rails error page with a much better and more useful error page. It is also usable outside of Rails.

![image](http://i.imgur.com/xR6Nz.png)

## Installation

Add this line to your application's Gemfile:

    gem 'better_errors'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install better_errors

## Usage

If you're using Rails, there's nothing else you need to do.

If you're not using Rails, you need to insert `BetterErrors::Middleware` into your middleware stack, and optionally set `BetterErrors.application_root` if you'd like Better Errors to abbreviate filenames within your application.

Here's an example using Sinatra:

```ruby
require "sinatra"
require "better_errors"

use BetterErrors::Middleware
BetterErrors.application_root = File.expand_path("..", __FILE__)

get "/" do
  raise "oops"
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
