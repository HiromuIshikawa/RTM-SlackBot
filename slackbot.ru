# coding: utf-8
require 'slack'
Slack.configure {|config| config.token = TOKEN}
client = Slack.realtime

client.on :hello do
  puts 'Successfully connected.'
end

client.on :message do |data|
  p data
  if data['text'] == 'おはよう' && data['subtype'] != 'bot_message'

    params = {
      channel: data['channel'],
      text: "<@#{data['user']}> おやすみ",
    }
    p params
    Slack.chat_postMessage params
  end # respond to messages
end

client.start
