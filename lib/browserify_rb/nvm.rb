require "browserify_rb/popen3"
require "stringio"

class BrowserifyRb
  class Nvm
    NVM_SH = File.join(__dir__, "nvm.sh")

    def initialize nvm_dir = "#{ENV["HOME"]}/.nvm"
      @nvm_dir = nvm_dir
    end

    def env
      { "NVM_DIR" => @nvm_dir }
    end

    def run(
          cmd,
          stdin: "",
          stdout_handler: proc{|d| STDOUT.print d },
          stderr_handler: proc{|d| STDERR.print d },
          node_ver: "stable",
          env: {})
      new_env = (env).merge(self.env)
      cmd = <<-CMD
        source "#{NVM_SH}" || {
          printf "Abort\n" >&2
          exit 1
        }
        if ! nvm use "#{node_ver}" >&2; then
          nvm install "#{node_ver}" >&2
          nvm use "#{node_ver}" >&2
        fi
        #{cmd}
      CMD

      BrowserifyRb::Popen3.async_exec(
        cmd,
        input: stdin, env: new_env,
        stdout_handler: stdout_handler,
        stderr_handler: stderr_handler
      )
    end

    def self.version
      out = StringIO.new
      err = StringIO.new
      cmd = <<-CMD
        source "#{NVM_SH}" || {
          printf "Abort\n" >&2
          exit 1
        }
        nvm --version
      CMD

      st = BrowserifyRb::Popen3.async_exec(
        cmd,
        stdout_handler: proc {|d| out << d },
        stderr_handler: proc {|d| err << d }
      ).value
      raise "non-zero exit status: #{status.to_i}\n#{err}" unless st.success?

      out.string.strip
    end
  end
end
