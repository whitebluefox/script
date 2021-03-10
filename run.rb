require 'httparty'
require 'aws-sdk-s3'
require 'dotenv/load'

`ffmpeg -i test.mp4 -vn -acodec libopus audio.ogg`

Aws.config.update(
  region: 'ru-central1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
)
s3 = Aws::S3::Client.new(endpoint: "https://storage.yandexcloud.net")

File.open('audio.ogg', 'r') do |file|
  pp = s3.put_object({
    bucket: 'teststask',
    key: 'audio.ogg',
    body: file
  })
    puts pp
end

options = {
  headers: {"Authorization" => "Api-Key #{ENV['API_KEY']}"},
  body: {
    "config" => {
        "specification" => {
            "languageCode" => "ru-RU"
        }
    },
    "audio" => {
        "uri" => "https://storage.yandexcloud.net/teststask/audio.ogg"
    }
  }.to_json
}

response = HTTParty.post('https://transcribe.api.cloud.yandex.net/speech/stt/v2/longRunningRecognize', options).to_h

option = {
   headers: {"Authorization" => "Api-Key #{ENV['API_KEY']}"}
}

done = false
until done
  yandex_answer = HTTParty.get("https://operation.api.cloud.yandex.net/operations/#{response['id']}", option).to_h
  puts yandex_answer
  done = yandex_answer['done']
  sleep 2
end

yandex_array = yandex_answer["response"]["chunks"]
yandex_text = []

yandex_array.each do |elem|
  yandex_text << elem["alternatives"].first["text"]
end

pp yandex_text.uniq!

`touch test.txt`

File.open("test.txt", 'w') { |file| file.write(":#{yandex_text.join(' ')}") }
