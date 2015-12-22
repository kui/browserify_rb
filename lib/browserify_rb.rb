require "browserify_rb/version"
require "browserify_rb/nvm"

require "stringio"

class BrowserifyRb
  DEFAULT_NVM_DIR = "#{ENV["HOME"]}/.nvm"

  def initialize(
        browserify_opts: "", node_ver: "stable", env: {},
        nvm_dir: DEFAULT_NVM_DIR, suppress_stderr: false)
    @nvm = BrowserifyRb::Nvm.new nvm_dir
    @node_ver = node_ver
    @env = env
    @browserify_opts = browserify_opts
    @suppress_stderr = suppress_stderr
    @prepared = false
  end

  def prepare
    cmd = <<-CMD
      if ! npm ls -g browserify &>/dev/null; then
        npm install -g browserify >&2
      fi
    CMD
    stdout_handler = proc {|d| }
    stderr_handler = @suppress_stderr ?
                       proc {|d| } :
                       proc {|d| STDERR.print d}
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
      if ! npm ls -g browserify &>/dev/null; then
        npm install -g browserify >&2
      fi
      browserify #{@browserify_opts} -- -
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
