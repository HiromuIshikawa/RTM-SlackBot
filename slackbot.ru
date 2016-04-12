# coding: utf-8
require 'slack'
require "open-uri"
require "FileUtils"

Slack.configure {|config| config.token = 'TOKEN'}
client = Slack.realtime

def save_image(url)
  # ready filepath
  fileName = File.basename(url)
  dirName = "~/SlackBot/file"
  filePath = dirName + fileName

  # create folder if not exist
  FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)

  # write image adata
  open(filePath, 'wb') do |output|
    open(url) do |data|
      output.write(data.read)
    end
  end
end

client.on :hello do
  puts 'Successfully connected.'
end

client.on :message do |data|
  if data['text'] == 'おはよう' && data['subtype'] != 'bot_message'

    params = {
      token: 'TOKEN',
      channel: data['channel'],
      as_user: true,
      text: "<@#{data['user']}> おやすみ",
    }
    Slack.chat_postMessage params
  end # respond to messages
end

client.on :file_created do |data|
  p "aaaaaaaa"
  p data["file"]["thumb_360"]
end

client.start
