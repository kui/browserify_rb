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
          cmd,
          input: "",
          env: {},
          stdout_handler: DEFAULT_STDOUT_HANDLER,
          stderr_handler: DEFAULT_STDERR_HANDLER,
          spawn_opts: {},
          chunk_size: CHUNK_SIZE)
      Thread.fork do
        begin
          stdin, stdout, stderr, wait_thr = Open3.popen3 env, cmd, spawn_opts

          input = input.is_a?(String) ?
                     StringIO.new(input) :
                     iput
          input_buff = ""
          opened_ins = [stdin]
          opened_outs = [stdout, stderr]
          handlers = {
            stdout => stdout_handler,
            stderr => stderr_handler
          }
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
                  d = out.readpartial chunk_size
                  handlers[out].call d
                end
              end
            end

            if not ins.nil? and ins.include? stdin
              if input.eof?
                stdin.close
                opened_ins.delete stdin
              elsif input_buff.empty?
                d = input.readpartial(chunk_size)
                bytes = stdin.write_nonblock(d)
                input_buff = d[bytes .. -1]
              else
                bytes = stdin.write_nonblock(input_buff)
                input_buff = d[bytes .. -1]
              end
            end
          end

          wait_thr.value
        rescue => e
          LOG.error e
          nil
        end
      end
    end
  end
end
