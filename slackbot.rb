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
  params = {inputBase64: img, apiKey: $conf["pux_token"], optionFlgMinFaceWidth: 1, facePartsCoordinates: 0, blinkJudge: 0, angleJudge: 0, enjoyJudge: 1, response: "json"}
  req.set_form_data(params)
  res = http.request(req)
  p res
  hash = JSON.parse(res.body)
  return hash
end

def generate_postMessage(params, res)

  animal_table = {"cat"=>"猫","dog"=>"犬","racoonDog"=>"タヌキ","fox"=>"キツネ","squirrel"=>"リス","fish"=>"魚","unknown"=>":question:"}
  gender_table = [{"color"=>"#4682b4","result"=>"男"},{"color"=>"#dc143c","result"=>"女"}]
  result = res['results']['faceRecognition']
  if result["errorInfo"] == "NoFace"
    params[:text] = "顔が検出されませんでした"
    return params
  else
    detected = result['detectionFaceNumber']
    params[:text] = "#{detected}人の顔が検出されました"
    info = result['detectionFaceInfo']
    attach = []
    p detected
    detected.times do |i|
      attach[i] = Hash.new
      enjoy = info[i]['enjoyJudge']
      gender = gender_table[info[i]['genderJudge']['genderResult']]
      smile = info[i]['smileJudge']['smileLevel']
      animal = animal_table[enjoy['similarAnimal']]
      color = gender["color"]
      m_f = gender["result"]
      age = info[i]['ageJudge']['ageResult']
      doya = enjoy['doyaLevel']
      trouble = enjoy['troubleLevel']

      attach[i]["color"] = color
      attach[i]["text"] = "#{age}歳 #{m_f} #{animal}顔\n\n笑顔度:#{smile}\n困り顔度:#{trouble}\nドヤ顔度:#{doya}"
    end
    params[:attachments] = attach.to_json
    return params
  end
end

client.on :hello do
  puts 'Successfully connected.'
end


client.on :file_shared do |data|
  p data
  p "occered file_shared event"
  params ={
    :as_user => true,
    :channel => data['file']['channels'][0],
    :text => "ファイルがシェアされました．JPEG形式のファイルで顔検出が可能です．"
  }
  if data['file']['filetype'] == 'jpg'
    img = get_img(data['file']['thumb_480'])
    res = apipost(img)
    p res
    params = generate_postMessage(params, res)
  end
  p params
  p Slack.chat_postMessage(params)

end

client.start
