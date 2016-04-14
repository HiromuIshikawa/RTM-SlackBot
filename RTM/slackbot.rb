# coding: utf-8
require 'slack'
require "open-uri"

Slack.configure {|config| config.token = 'xoxb-33480878065-AVr0LyniFeLefUQgAsXGpqaU'}

client = Slack.realtime


client.on :hello do
  puts 'Successfully connected.'
end

client.on :message do |data|
  if data['text'] == 'おはよう' && data['subtype'] != 'bot_message'

    params = {
      channel: data['channel'],
      as_user: true,
      text: "<@#{data['user']}> おやすみ",
    }
    Slack.chat_postMessage params
  end # respond to messages
end


client.on :file_shared do |data|
  p data['file']['permalink_public']
  params ={
    as_user: true,
    channel: data['file']['channels'][0],
    text: "<@#{data['file']['user']}> is shared a file"
  }
   Slack.chat_postMessage params
end

client.start
