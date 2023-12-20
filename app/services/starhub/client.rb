module Starhub
  class Client
    class ApiError < StandardError; end
    include Singleton

    API_VERSION = '/api/v1'

    def get(path, params = {})
      starhub_api_connection.get(request_path(path), params)
    rescue Faraday::ConnectionFailed
      raise StarhubError, "Git服务器超时"
    end

    def post(path, options = {})
      starhub_api_connection.post(request_path(path)) do |req|
        req.body = options.to_json
      end
    rescue Faraday::ConnectionFailed
      raise StarhubError, "Git服务器超时"
    end

    def put(path, options = {})
      starhub_api_connection.put(request_path(path)) do |req|
        req.body = options.to_json
      end
    rescue Faraday::ConnectionFailed
      raise StarhubError, "Git服务器超时"
    end

    def delete(path, params = {})
      starhub_api_connection.delete(request_path(path), params)
    rescue Faraday::ConnectionFailed
      raise StarhubError, "Git服务器超时"
    end

    private

    def request_path(path)
      API_VERSION + path
    end

    def starhub_api_connection
      Faraday.new(
        url: Rails.application.credentials.starhub_api.send("#{Rails.env}").base_url,
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => Rails.application.credentials.starhub_api.send("#{Rails.env}").token
        })
    end
  end
end
