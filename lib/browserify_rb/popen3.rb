require "open3"
require "stringio"
require "logger"

class BrowserifyRb
  module Popen3
    LOG = Logger.new(STDERR)

    CHUNK_SIZE = 2000
    DEFAULT_STDOUT_HANDLER = proc {|data| STDOUT.write data }
    DEFAULT_STDERR_HANDLER = proc {|data| STDERR.write data }

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

      Thread.fork do
        in_buf = StringIO.new input
        opened_ins = [stdin]
        opened_outs = [stdout, stderr]
        handlers = {
          stdout => stdout_handler,
          stderr => stderr_handler
        }
        begin
          while not opened_outs.empty?
            ios = IO.select opened_outs, opened_ins, nil, 1
            if ios.nil? and Process.waitpid(wait_thr.pid, Process::WNOHANG)
              break
            end

            outs, ins, = ios

            if not outs.nil?
              outs.each do |out|
                if out.eof?
                  out.close
                  opened_outs.delete out
                else
                  d = out.readpartial CHUNK_SIZE
                  handlers[out].call d
                end
              end
            end

            if not ins.nil? and ins.include? stdin
              if in_buf.eof?
                stdin.close
                opened_ins.delete stdin
              else
                d = in_buf.readpartial(CHUNK_SIZE)
                bytes = stdin.write_nonblock(d)
                in_buf.seek(bytes - d.bytesize, IO::SEEK_CUR)
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
