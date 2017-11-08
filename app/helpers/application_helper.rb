
module ApplicationHelper
    require "json"
    require "faraday"
    class Request
        API_ENDPOINT = "https://api.quickblox.com"

        attr_accessor :params, :headers, :method, :response, :response_body, :errors
        attr_reader :connection
        attr_reader :uri

        def initialize
            @connection = Faraday.new(url: Request::API_ENDPOINT) do |faraday|
                faraday.request  :url_encoded
                faraday.response :logger
                faraday.adapter  Faraday.default_adapter
            end

            @headers = {}
        end

        def header(key, value)
            headers[key] = value
        end

        def before_request
        end

        def after_request
        end

        def execute
            before_request

            get    if @method == :get
            post   if @method == :post
            put    if @method == :put
            delete if @method == :delete

            if @response.status != 404 && @response.body.length > 1
                @response_body = JSON.parse(@response.body)
            else
                @response_body = {}
            end

            @errors = @response_body["errors"] if @response.status != 404
            if @errors
                if @errors.kind_of?(Hash)
                raise ZQuickblox::Error.new(messages: @errors["base"]) if !@errors["base"].nil?
                message = ""
                @errors.each do |key, value|
                    message += "; " + key
                    message += " " + value.join(", ")
                end
                raise ZQuickblox::Error.new(messages: message)
                end
            end

            after_request
        end

        private

        def handle_request(request)
            request.url        @uri
            request.headers =  @headers
            request.body    =  @params
        end

        def get
            @response = @connection.get do |request|
                handle_request(request)
            end
        end

        def post
            @response = @connection.post do |request|
                handle_request(request)
            end
        end

        def put
            @response = @connection.put do |request|
                handle_request(request)
            end
        end

        def delete
            @response = @connection.delete do |request|
                handle_request(request)
            end
        end
    end
    class Session < Request
        attr_accessor :login, :password
        attr_reader :token, :session

        class << self
            def create(login=nil, password=nil)
                session = ApplicationHelper::Session.new
                session.login    = login
                session.password = password
                session.execute
                return session
            end
        end

        def initialize
            super
            @uri = "/session.json"
            @method = :post
        end

        def before_request
            build_params
        end

        def execute
            super
            @session = @response_body["session"]
            @token   = @session["token"]
        end

        def generate_signature(params, secret)
            pairs = params.map { |key, value| "#{key}=#{value}" }
            pairs.sort!
            body  = pairs.join("&")
            return hmac_sha(body, secret)
        end

        private

        def hmac_sha(data, secret)
            require "base64"
            require "cgi"
            require "openssl"
            hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret.encode("ASCII"), data.encode("ASCII"))
            return hmac
        end
        def build_params
            @params = {
                "application_id": "62976",
                "auth_key": "ZZfLQREvVpPsEG-",
                "timestamp": Time.now.to_i,
                "nonce": rand(2000)
            }
            @params["user[login]"] = @login if @login
            @params["user[password]"] = @password if @password
            @params["signature"] = generate_signature(@params, "dYxJxuMyfMr7BaV")
        end
    end
end
