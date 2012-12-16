# Better Errors

Better Errors replaces the standard Rails error page with a much better and more useful error page. It is also usable outside of Rails in any Rack app as Rack middleware.

![image](http://i.imgur.com/zYOXF.png)

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

**NOTE:** It is *critical* you put better\_errors in the **development** section. **Do NOT run better_errors in production, or on Internet facing hosts.**

If you would like to use Better Errors' **advanced features** (REPL, local/instance variable inspection, pretty stack frame names), you need to add the [`binding_of_caller`](https://github.com/banister/binding_of_caller) gem by [@banisterfiend](http://twitter.com/banisterfiend) to your Gemfile:

```ruby
gem "binding_of_caller"
```

This is an optional dependency however, and Better Errors will work without it.

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

## Compatibility

* **Supported**
  * MRI 1.9.2, 1.9.3
  * JRuby (1.9 mode) - *advanced features unsupported*
  * Rubinius (1.9 mode) - *advanced features unsupported*
* **Coming soon**
  * MRI 2.0.0 - the official API for grabbing caller bindings is slated for MRI 2.0.0, but it has not been implemented yet

## Known issues

* Calling `yield` from the REPL segfaults MRI 1.9.x.

## Get in touch!

If you're using better_errors, I'd love to hear from you. Drop me a line and tell me what you think!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
