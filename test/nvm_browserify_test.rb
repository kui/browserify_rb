require 'test_helper'
require 'fileutils'

class BrowserifyRb::Nvm::BrowserifyTest < Minitest::Test
  NVM_DIR = "#{ENV["PWD"]}/.nvm"

  BrowserifyRb::Nvm::Browserify.new(
    nvm_dir: NVM_DIR,
    node_ver: "stable"
  ).prepare

  Minitest.after_run do
    FileUtils.rm_rf NVM_DIR
    FileUtils.rm_rf "node_modules"
  end

  def test_it_run_browserify
    code = "console.log('foooooo')"
    result = BrowserifyRb::Nvm::Browserify.compile code, nvm_dir: NVM_DIR, node_ver: "stable"
    matcher = Regexp.new(Regexp.quote(code))
    assert_match matcher, result
  end

  def test_it_run_browserify_with_babelify
    code_fagment = "console.log('foooooo');"
    code = "() => { #{code_fagment} }"
    b = BrowserifyRb::Nvm::Browserify.new(
      required_modules: [
        "babelify",
        "babel-preset-es2015",
      ],
      browserify_opts: "-t [ babelify --presets es2015 ]",
      nvm_dir: NVM_DIR,
      node_ver: "stable"
    )
    result = b.compile code
    assert_match code_fagment, result
    refute_match "() ->", result
    assert_match "function", result
  end

  def test_it_run_browserify_with_nvmrc
    FileUtils.cd File.join(__dir__, "nvmrc_test") do
      code = "console.log('foooooo')"
      result = BrowserifyRb::Nvm::Browserify.compile code, nvm_dir: NVM_DIR
      matcher = Regexp.new(Regexp.quote(code))
      assert_match matcher, result
    end
  end
end
