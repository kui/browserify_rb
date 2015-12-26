require 'test_helper'
require 'fileutils'

class BrowserifyRbTest < Minitest::Test
  NVM_DIR = "#{ENV["PWD"]}/.nvm"

  BrowserifyRb.new.prepare

  Minitest.after_run do
    FileUtils.rm_rf NVM_DIR
    FileUtils.rm_rf "node_modules"
  end

  def test_that_it_has_a_version_number
    refute_nil ::BrowserifyRb::VERSION
  end

  def test_it_run_browserify
    code = "console.log('foooooo')"
    result = BrowserifyRb.compile code, nvm_dir: NVM_DIR
    matcher = Regexp.new(Regexp.quote(code))
    assert_match matcher, result
  end

  def test_it_run_browserify_with_babelify
    code_fagment = "console.log('foooooo');"
    code = "() => { #{code_fagment} }"
    b = BrowserifyRb.new(
      required_modules: [
        "babelify",
        "babel-preset-es2015",
      ],
      browserify_opts: "-t [ babelify --presets es2015 ]"
    )
    result = b.compile code
    assert_match code_fagment, result
    refute_match "() ->", result
    assert_match "function", result
  end
end
