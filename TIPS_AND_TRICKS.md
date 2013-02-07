# Tips and Tricks

Below are a collection of handy tips and tricks submitted by users to help you get the most out of Better Errors.

If you know something you think would be valuable to share, please do! Pull requests are always appreciated.

### View last error

Better Errors saves the most recent error page displayed at `/__better_errors`.

This can be handy if you aren't able to see the error page served up when the exception occurred, eg. if the errored request was an AJAX or curl request.

### Adjusting the project base path for the editor link

If your Rails app is running from a shared folder in a VM, the path to your source files from Rails' perspective could be different to the path seen by your editor.

You can adjust the path used to generate open-in-editor links by putting this snippet of code in an initializer:

```ruby
if defined? BetterErrors
  BetterErrors.editor = proc { |full_path, line|
    full_path = full_path.sub(Rails.root.to_s, your_local_path)
    "my-editor://open?url=file://#{full_path}&line=#{line}"
  }
end
```

If you're working on a project with other developers, your base path may be not be the same as the other developers'.

You can use an environment variable to work around this by replacing `your_local_path` in the snippet above with `ENV["BETTER_ERRORS_PROJECT_PATH"]` and starting your Rails server like this:

```shell
$ BETTER_ERRORS_PROJECT_PATH=/path/to/your/app rails server
```

### Opening files in RubyMine

Users of RubyMine on OS X can follow the instructions provided at http://devnet.jetbrains.com/message/5477503 to configure Better Errors to open files in RubyMine.

