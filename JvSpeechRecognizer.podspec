#
# Be sure to run `pod lib lint JvSpeechRecognizer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JvSpeechRecognizer'
  s.version          = '1.0.0'
  s.summary          = 'An encapsulation of SFSpeechRecognizer.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
It is an encapsulation of SFSpeechRecognizer. With it you can use the iOS native speech recognition function in an easier way.
                       DESC

  s.homepage         = 'https://github.com/ijovi23/JvSpeechRecognizer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ijovi23' => 'ijovi23@gmail.com' }
  s.source           = { :git => 'https://github.com/ijovi23/JvSpeechRecognizer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'JvSpeechRecognizer/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JvSpeechRecognizer' => ['JvSpeechRecognizer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'Speech'
  # s.dependency 'AFNetworking', '~> 2.3'
end
