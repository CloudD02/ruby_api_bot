require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'
require 'sinatra'


Thread.new do
  EM.run do
  end
end

get '/' do
  if params['code']
    rc = HTTP.post("https://slack.com/api/oauth.access", params:{
      client_id: ENV['SLACK_CLIENT_ID'],
      client_secret: ENV['SLACK_CLIENT_SECRET'],
      code: params['code']
    })
    rc = JSON.parse(rc)
    token = rc['bot']['bot_access_token']

    rc = HTTP.post("https://slack.com/api/rtm.start", params:{
      token: token
    })
    rc = JSON.parse(rc.body)
    url = rc['url']

    ws = Faye::WebSocket::Client.new(url)
    ws.on :open do
      p [:open]
    end

    ws.on :message do |event|
      p [:message, JSON.parse(event.data)]
      data = JSON.parse(event.data)
      if data['text'] != nil
        command = data['text']
        link = command[0]
        if link == 'w'
          splited = command.split(' ')
          indx = 2
          copy = ''
          search = splited[1]
          while indx < splited.length  do
              search = "#{search} #{splited[indx]}"
              indx +=1
          end

          search = search.capitalize
          indx = 0
          while indx < search.length  do
             if search[indx] == ' '
               copy[indx] = '_'
               copy[indx+1] = search[indx+1].upcase
               indx +=1
            else
                copy[indx] = search[indx]

             end
             indx +=1
          end
          ws.send({ type: 'message',
            text: "https://es.wikipedia.org/wiki/#{copy}",
            channel: data['channel'] }.to_json)
        end
        if data['text'] == 'hi'
          ws.send({ type: 'message',
            text: 'https://media.giphy.com/media/a1QLZUUtCcgyA/giphy.gif',
            channel: data['channel'] }.to_json)
        end
        if data['text'] == 'date'
          time = Time.new
          ws.send({ type: 'message',
            text: time.strftime("%Y %B %A %H:%M:%S") ,
            channel: data['channel'] }.to_json)
        end
      end
    end
    ws.on :close do
      p [:close, event.code, event.reason]
      ws = nil
      EM.stop
    end
    "Bot succesfully installed"
  else
    "Hello world"
  end
end
