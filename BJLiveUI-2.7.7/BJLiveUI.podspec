Pod::Spec.new do |s|
  s.name = "BJLiveUI"
  s.version = "2.7.7"
  s.summary = "BJLiveUI SDK."
  s.license = "MIT"
  s.authors = {"MingLQ"=>"minglq.9@gmail.com"}
  s.homepage = "http://www.baijiayun.com/"
  s.description = "BJLiveUI SDK for iOS."
  s.requires_arc = true
  s.source = { :path => '.' }

  s.ios.deployment_target    = '9.0'
  s.ios.vendored_framework   = 'ios/BJLiveUI.embeddedframework/BJLiveUI.framework'
end
