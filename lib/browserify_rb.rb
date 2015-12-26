require "browserify_rb/version"
require "browserify_rb/nvm"

require "stringio"
require "logger"

class BrowserifyRb
  DEFAULT_NVM_DIR = "#{ENV["HOME"]}/.nvm"
  LOG = Logger.new(STDERR)
  LOG.level = Logger::Severity.const_get(ENV["LOG"] || "INFO")

  def initialize(
        browserify_opts: "", node_ver: "stable", env: {},
        nvm_dir: DEFAULT_NVM_DIR, suppress_stderr: false,
        required_modules: nil)
    @nvm = BrowserifyRb::Nvm.new nvm_dir
    @node_ver = node_ver
    @env = env
    @browserify_opts = browserify_opts
    @suppress_stderr = suppress_stderr
    @prepared = false
    @modules = required_modules
  end

  def prepare
    ms = ["browserify", *@modules].map{|m| %Q!"#{m}"! }.join(" ")
    cmd = "npm install #{ms}"
    stdout_handler = proc {|d| }
    stderr_handler = @suppress_stderr ?
                       proc {|d| } :
                       proc {|d| STDERR.print d}
    LOG.debug "run: #{cmd}"
    status = @nvm.run(
      cmd,
      node_ver: @node_ver,
      env: @env,
      stdout_handler: stdout_handler,
      stderr_handler: stderr_handler
    ).value
    raise "non-zero exit status: #{status.to_i}" unless status.success?
    @prepared = true
  end

  def compile source
    prepare unless @prepared

    out_buf = StringIO.new
    cmd = <<-CMD
      node_modules/.bin/browserify #{@browserify_opts} -- -
    CMD
    stdout_handler = proc {|d| out_buf << d }
    stderr_handler = @suppress_stderr ?
                       proc {|d| } :
                       proc {|d| STDERR.print d}
    status = @nvm.run(
      cmd,
      stdin: source,
      node_ver: @node_ver,
      env: @env,
      stdout_handler: stdout_handler,
      stderr_handler: stderr_handler
    ).value
    raise "non-zero exit status: #{status.to_i}" unless status.success?

    return out_buf.string
  end

  def self.compile(
        source, browserify_opts: "", node_ver: "stable", env: {},
        nvm_dir: DEFAULT_NVM_DIR, suppress_stderr: false)
    new(
      browserify_opts: browserify_opts,
      node_ver: node_ver,
      env: env,
      nvm_dir: nvm_dir,
      suppress_stderr: suppress_stderr
    ).compile(source)
  end
end
