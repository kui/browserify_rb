# BrowserifyRb

browserify wrapper with nvm to install node automatically.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'browserify_rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install browserify_rb

## Usage

```ruby
require "browserify_rb"

br = BrowserifyRb.new
puts br.compile("console.log('foo');")

puts BrowserifyRb.compile("console.log('bar');")
```

`node` nor `nvm` are not required.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/browserify_rb.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

