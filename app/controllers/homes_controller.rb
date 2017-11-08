require 'net/http'
require 'uri'
require 'json'
class HomesController < ApplicationController
  def index
    session = ApplicationHelper::Session.create("adamski8","adamski88stemChatUser")
    @token = session.token

    #create dialog
    uri = URI.parse("https://api.quickblox.com/chat/Dialog.json")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Qb-Token"] = @token
    request.body = JSON.dump({
        "type" => 3,
        "name" => "Dialog1",
        "occupants_ids" => "35273123"
    })

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
    end
    @response_code = response.code
    @response_body = JSON.parse(response.body)
    @dialog_id = @response_body["_id"]


    #send message
    uri = URI.parse("https://api.quickblox.com/chat/Message.json")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Qb-Token"] = @token
    request.body = JSON.dump({
        "chat_dialog_id" => @dialog_id,
        "message" => "hello!This is the sample message from A",
        "recipient_id" => 343
       
    })

    req_options = {
    use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
    end

    @message_response_code = response.code
    @message_response_body = JSON.parse(response.body)

    # delete dialog
    uri = URI.parse("https://api.quickblox.com/chat/Dialog/"+@dialog_id+".json")
    request = Net::HTTP::Delete.new(uri)
    request.content_type = "application/json"
    request["Qb-Token"] = @token

    req_options = {
    use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
    end

    
  end
end
