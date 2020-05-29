#!/usr/bin/env ruby
# A quick and dirty implementation of an HTTP proxy server in Ruby
# because I did not want to install anything.
#
# Copyright (C) 2009-2014 Torsten Becker <torsten.becker@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'socket'
require 'uri'


class Proxy
  def run(port, delay)
    @port = port
    @delay = delay
    begin
      # Start our server to handle connections (will raise things on errors)
      @socket = TCPServer.new port

      # Handle every request in another thread
      loop do
        s = @socket.accept
        Thread.new s, &method(:handle_request)
      end

    # CTRL-C
    rescue Interrupt
      puts 'Got Interrupt..'
    # Ensure that we release the socket on errors
    ensure
      if @socket
        @socket.close
        puts 'Socked closed..'
      end
      puts 'Quitting.'
    end
  end

  def handle_request to_client
    request_line = to_client.readline

    verb    = request_line[/^\w+/]
    url     = request_line[/^\w+\s+(\S+)/, 1]
    version = request_line[/HTTP\/(1\.\d)\s*$/, 1]
    uri     = URI::parse url

    # Show what got requested
    puts((" %4s "%verb) + url)

    to_server = TCPSocket.new('localhost', 9090)

    sleep(@delay)

    to_server.write("#{verb} #{uri.path}?#{uri.query} HTTP/#{version}\r\n")

    content_len = 0

    loop do
      line = to_client.readline

      if line =~ /^Content-Length:\s+(\d+)\s*$/
        content_len = $1.to_i
      end

      # Strip proxy headers
      if line =~ /^proxy/i
        next
      elsif line.strip.empty?
        to_server.write("Connection: close\r\n\r\n")

        if content_len >= 0
          to_server.write(to_client.read(content_len))
        end

        break
      else
        to_server.write(line)
      end
    end

    buff = ""
    loop do
        to_server.read(4048, buff)
        to_client.write(buff)
      break if buff.size < 4048
    end

    # Close the sockets
    to_client.close
    to_server.close
  end

end
