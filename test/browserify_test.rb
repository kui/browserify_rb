require 'test_helper'

class BrowserifyRb::BrowserifyTest < Minitest::Test

  `npm install`

  def test_it_compile_js_code
    code = "console.log('foooo');"
    browserify = BrowserifyRb::Browserify.new(command: "$(npm bin)/browserify -")
    result = browserify.compile code

    assert_match code, result
    refute_equal code, result
  end
end
