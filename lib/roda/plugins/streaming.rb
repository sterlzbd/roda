# The streaming plugin is mostly based on Sinatra's
# implementation, which is also released under the MIT License:
#
# Copyright (c) 2007, 2008, 2009 Blake Mizerany
# Copyright (c) 2010, 2011, 2012, 2013, 2014 Konstantin Haase
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

class Roda
  module RodaPlugins
    module Streaming
      # Class of the response body in case you use #stream.
      #
      # Three things really matter: The front and back block (back being the
      # block generating content, front the one sending it to the client) and
      # the scheduler, integrating with whatever concurrency feature the Rack
      # handler is using.
      #
      # Scheduler has to respond to defer and schedule.
      class Stream
        include Enumerable

        class Scheduler
          def initialize(stream)
            @stream = stream
          end

          def schedule(*)
            yield
          rescue Exception
            @stream.close
            raise
          end

          def defer(*)
            yield
          end
        end

        def initialize(opts={}, &back)
          @scheduler = opts[:scheduler] || Scheduler.new(self)
          @back = back.to_proc
          @keep_open = opts[:keep_open]
          @callbacks = []
          @closed = false

          if opts[:callback]
            callback(&opts[:callback])
          end
        end

        def close
          return if closed?
          @closed = true
          @scheduler.schedule{@callbacks.each{|c| c.call}}
        end

        def each(&front)
          @front = front
          @scheduler.defer do
            begin
              @back.call(self)
            rescue Exception => e
              @scheduler.schedule{raise e}
            end
            close unless @keep_open
          end
        end

        def <<(data)
          @scheduler.schedule{@front.call(data.to_s)}
          self
        end

        def callback(&block)
          return yield if closed?
          @callbacks << block
        end

        alias errback callback

        def closed?
          @closed
        end
      end

      module InstanceMethods
        def stream(opts={}, &block)
          opts = opts.merge(:scheduler=>EventMachine) if !opts.has_key?(:scheduler) && env['async.callback']

          if opts[:loop]
            block = proc do |out|
              until out.closed?
                yield(out)
              end
            end
          end

          res = response
          request.halt [res.status || 200, res.headers, Stream.new(opts, &block)]
        end
      end
    end
  end

  register_plugin(:streaming, RodaPlugins::Streaming)
end
