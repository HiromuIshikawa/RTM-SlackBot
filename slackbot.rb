# coding: utf-8
require 'json'
require 'uri'
require 'slack'
require 'yaml'
require 'net/https'
require 'base64'

$conf = YAML.load_file('settings.yml') if File.exist?('settings.yml')
$token = $conf["bot_token"]

Slack.configure {|config| config.token = $token}

client = Slack.realtime

def get_img(url)
  uri = URI.parse(url)

  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = http.get(uri.path,{'Authorization' => "Bearer #{$token}"})
    p "get image binary"
    base64 = Base64.encode64(res.body)
    return base64
  end
end


def apipost(img)
  req_url = "http://#{$conf["pux_domain"]}:8080/webapi/face.do"
  uri = URI.parse(req_url)
  
  http = Net::HTTP.new(uri.host, uri.port)
  res = nil

  req = Net::HTTP::Post.new(uri.path)
  req["Content-Type"] = "application/x-www-form-urlencoded"
  params = {inputBase64: img, apiKey: $conf["pux_token"], optionFlgMinFaceWidth: 2, facePartsCoordinates: 0, blinkJudge: 0, angleJudge: 0, enjoyJudge: 1, response: "json"}
  req.set_form_data(params)
  res = http.request(req)
  p res
  hash = JSON.parse(res.body)
  return hash
end

client.on :hello do
  puts 'Successfully connected.'
end


client.on :file_shared do |data|
  p "occered file_shared event"
  params ={
    as_user: true,
    channel: data['file']['channels'][0],
    text: "<@#{data['file']['user']}> is shared a #{data['file']['filetype']} file"
  }
  Slack.chat_postMessage params
  if data['file']['filetype'] == 'jpg'
    img = get_img(data['file']['thumb_480'])
    res = apipost(img)
    p res
  end
end

client.start
