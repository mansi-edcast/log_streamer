require 'application_logs/stream'
class StreamsController < ApplicationController
	include ActionController::Live
	def live
		response.headers['Content-Type'] = 'text/event-stream'
    # hack due to new version of rack not supporting sse and sending all response at once: https://github.com/rack/rack/issues/1619#issuecomment-848460528
    response.headers['Last-Modified'] = Time.now.httpdate

    sse = SSE.new(response.stream, retry: 300, event: "log-stream")

    log_file = ApplicationLogs::Stream.new()

    sse.write(log_file.read(10))

    log_file.watch {|lines| sse.write(lines)}
  rescue ActionController::Live::ClientDisconnected
  	response.stream.close
  	sse.close
  rescue IOError
   	response.stream.close
  	sse.close
	ensure
		response.stream.close
  	sse.close
	end
end
