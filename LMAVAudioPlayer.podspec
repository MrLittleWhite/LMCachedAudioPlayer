

Pod::Spec.new do |s|

  s.name         = 'LMAVAudioPlayer'
  s.version      = '0.0.2'
  s.summary      = 'LMAVAudioPlayer is based on AVPlayer using AVAssetResourceLoader.'

 s.description  = <<-DESC
                     This version, http file and local file can be played by LMAVAudioPlayer. Play http file using AVAssetResourceLoader & local file do not use AVAssetResourceLoader.
                   DESC

  s.homepage     = 'https://github.com/MrLittleWhite/LMCachedAudioPlayer'

  s.license      = 'MIT'

  s.author             = { 'MrLittleWhite' => 'luffy243077002@163.com' }

  s.platform     = :ios, '7.0'

  s.ios.deployment_target = '7.0'

  s.source       = { :git => 'https://github.com/MrLittleWhite/LMCachedAudioPlayer.git', :tag => 'v0.0.2' }

  s.source_files  = 'LMAVAudioPlayer', 'LMCachedAudioPlayer/LMAVAudioPlayer/**/*'
  
  s.framework  = 'AVFoundation'
  s.dependency 'Reachability'

  s.requires_arc = true
end
