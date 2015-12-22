require "open3"
require "stringio"
require "logger"

class BrowserifyRb
  module Popen3
    LOG = Logger.new(STDERR)

    CHUNK_SIZE = 2000
    DEFAULT_STDOUT_HANDLER = proc {|data| STDOUT.print data }
    DEFAULT_STDERR_HANDLER = proc {|data| STDERR.print data }

    def self.async_exec(
          input: "",
          env: {},
          cmd: nil,
          stdout_handler: DEFAULT_STDOUT_HANDLER,
          stderr_handler: DEFAULT_STDERR_HANDLER,
          spawn_opts: {},
          chunk_size: CHUNK_SIZE)

      raise ArgumentError, "'cmd' require" if cmd.nil?

      stdin, stdout, stderr, wait_thr = Open3.popen3 env, cmd, spawn_opts

      in_buf = StringIO.new input
      opened_ins = [stdin]
      opened_outs = [stdout, stderr]

      Thread.fork do
        begin
          while not opened_outs.empty?
            ios = IO.select opened_outs, opened_ins, nil, 1
            if ios.nil? and Process.waitpid(wait_thr.pid, Process::WNOHANG)
              break
            end

            outs, ins, = ios

            unless outs.nil?
              if outs.include? stdout
                begin
                  d = stdout.readpartial CHUNK_SIZE
                  stdout_handler.yield d
                rescue EOFError
                  opened_outs.delete stdout
                end
              end

              if outs.include? stderr
                begin
                  d = stderr.readpartial CHUNK_SIZE
                  stderr_handler.yield d
                rescue EOFError
                  opened_outs.delete stderr
                end
              end
            end

            if not ins.nil? and ins.include? stdin
              i = begin
                    in_buf.readpartial CHUNK_SIZE
                  rescue EOFError
                    nil
                  end
              if i.nil?
                stdin.close
                opened_ins.delete stdin
              else
                bytes = stdin.write_nonblock(i)
                in_buf.seek bytes - i.bytesize, IO::SEEK_CUR
              end
            end
          end
        rescue => e
          LOG.error e
        end
      end

      wait_thr
    end
  end
end
