Pod::Spec.new do |s|
    
    s.name          = "BJLiveUI"
    s.version       = "2.7.8"
    s.summary       = "BJLiveUI SDK."
    s.description   = "BJLiveUI SDK for iOS."
    
    s.homepage      = "http://www.baijiayun.com/"
    s.license       = "MIT"
    s.author        = { "MingLQ" => "minglq.9@gmail.com" }
    
    s.platform      = :ios, "9.0"
    s.ios.deployment_target = "9.0"
    
    s.source        = {
        :git => "https://github.com/jonkerit/liveFrameWorks.git",
        :tag => s.version.to_s
    }
    
    s.requires_arc = true
    
    # use <"> but not <'> for #{s.name} and #{s.version}
    s.pod_target_xcconfig = {
        "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES", # requies both `user_target_xcconfig` and `pod_target_xcconfig`
        "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) BJLIVEUI_NAME=#{s.name} BJLIVEUI_VERSION=#{s.version}"
    }
    s.user_target_xcconfig = {
        "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES" # requies both `user_target_xcconfig` and `pod_target_xcconfig`
    }
    
    s.default_subspecs = ['static.source']
    
    s.subspec 'static' do |ss|
        ss.preserve_paths       = 'frameworks/BJLiveUI.framework'
        ss.source_files         = 'frameworks/BJLiveUI.framework/Versions/A/Headers/**/*.h'
        ss.public_header_files  = 'frameworks/BJLiveUI.framework/Versions/A/Headers/**/*.h'
        ss.resources            = ['frameworks/BJLiveUI.framework/Versions/A/Resources/BJLiveUI.bundle', 
                                   'frameworks/BJLiveUI.framework/Versions/A/Resources/BJLiveUIMedia.bundle', 
                                   'frameworks/BJLiveUI.framework/Versions/A/Resources/BJLSurfaceClass.bundle',
                                   'frameworks/BJLiveUI.framework/Versions/A/Resources/BJLInteractiveClass.bundle',]
        ss.vendored_frameworks  = 'frameworks/BJLiveUI.framework'
        ss.dependency 'BJLiveUI/static.dependencies'
    end
    
    s.subspec 'static.source' do |ss|
        ss.public_header_files = [
            'classes/**/BJLiveUI.h',
            'classes/**/BJLRoomViewController.h',
            'classes/**/BJLOverlayViewController.h',
            'classes/**/BJLOverlayContainerController.h',
            'interactive/**/BJLIcRoomViewController.h',
            'surface/**/BJLScRoomViewController.h',
        ]
        ss.source_files  = ["classes", "classes/**/*.{h,m}", "interactive", "interactive/**/*.{h,m}", "surface", "surface/**/*.{h,m}"]
        ss.resource_bundles = {
            "BJLiveUI" => ["bundles/BJLiveUI/**/*.*"],
            "BJLiveUIMedia" => ["bundles/like.mp3"],
            "BJLSurfaceClass" => ["bundles/BJLSurfaceClass/**/*.*"],
            "BJLInteractiveClass" => ["bundles/BJLInteractiveClass/**/*.*"],
        }
        ss.dependency 'BJLiveUI/static.dependencies'
    end
    
    s.subspec 'static.dependencies' do |ss|
        ss.frameworks = ['CoreGraphics', 'Foundation', 'MobileCoreServices', 'Photos', 'SafariServices', 'UIKit', 'WebKit', 'SpriteKit']
        ss.dependency "BJLiveBase",                          ">= 2.8.0"
        ss.dependency "BJLiveBase/Base",                     ">= 2.8.0"
        ss.dependency "BJLiveBase/Auth",                     ">= 2.8.0"
        ss.dependency "BJLiveBase/HUD",                      ">= 2.8.0"
        ss.dependency "BJLiveBase/Networking",               ">= 2.8.0"
        ss.dependency "BJLiveBase/WebImage/AFNetworking",    ">= 2.8.0"
        
        ss.dependency "BJLiveCore", "~> 2.7.4"
        ss.dependency "QBImagePickerController", "~> 3.0"
    end
    
end
