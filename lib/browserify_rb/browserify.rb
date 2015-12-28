require "browserify_rb/popen3"

require "stringio"
require "logger"

class BrowserifyRb::Browserify
  LOG = Logger.new(STDERR)
  LOG.level = Logger::Severity.const_get(ENV["LOG"] || "INFO")
  LOG.progname = BrowserifyRb::Browserify

  def initialize command: "browserify -", suppress_stderr: false
    @command = command
    @suppress_stderr = suppress_stderr
  end

  def compile source
    out_buf = StringIO.new
    stdout_handler = proc {|d| out_buf << d }
    stderr_handler = @suppress_stderr ? proc { } : proc {|d| STDERR.print d }

    LOG.debug "run: #{@command}"
    status = BrowserifyRb::Popen3.async_exec(
      @command,
      input: source,
      stdout_handler: stdout_handler,
      stderr_handler: stderr_handler,
    ).value
    raise "non-zero exit status: #{status.to_i}" unless status.success?

    out_buf.string
  end

  def self.compile source, command: "browserify -", suppress_stderr: false
    new(command: command, suppress_stderr: suppress_stderr).compile(source)
  end
end
