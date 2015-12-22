require 'test_helper'
require 'fileutils'

class BrowserifyRbTest < Minitest::Test
  NVM_DIR = "#{ENV["PWD"]}/.nvm"

  def test_that_it_has_a_version_number
    refute_nil ::BrowserifyRb::VERSION
  end

  def test_it_run_browserify
    code = "console.log('foooooo')"
    result = BrowserifyRb.compile code, nvm_dir: NVM_DIR
    matcher = Regexp.new(Regexp.quote(code))
    assert_match matcher, result
  ensure
    FileUtils.rm_rf NVM_DIR
  end
end
