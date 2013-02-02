# Tips And Tricks

### Adjusting the project base path for the editor link (e.g. if your rails app is running in a VM)

Add this code to your development environment initializer (in rails it is config/environments/development.rb)
```ruby
if defined? BetterErrors
BetterErrors.editor = Proc.new{|full_path,line|
  full_path = full_path.sub(Rails.root.to_s, your_local_path)
  "my-editor://open?url=file://#{full_path}&line=#{line}"
}
end
```
In this case ```your_local_path``` is the project base path with which your editor is working.

**Note** If you are working with more than one coder on a project you probably want ```your_local_path``` to be something dynamic (except if the project on every coders machine is in the same path).
In this case you can set an environment variable inside the VM (Linux in most cases) and pick it up in the intializer.
For instance (in Ubuntu) add ```export BETTER_ERRORS_FILENAME_PREFIX='/Users/your_name/project/path'``` to ```/etc/profile.d/my_env_vars``` and change the ```full_path``` line like this:
```
full_path = full_path.sub(Rails.root.to_s, ENV['BETTER_ERRORS_FILENAME_PREFIX']) if ENV['BETTER_ERRORS_FILENAME_PREFIX']
```

### Opening files in RubyMine (This trick works for OS-X only so far)
Apply the trick shown above to customize ```BetterErrors.editor```.
Then go to http://devnet.jetbrains.com/message/5477503?tstart=0 and follow the steps that Gerard describes.
