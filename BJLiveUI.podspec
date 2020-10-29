Pod::Spec.new do |s|
    
    s.name          = "BJLiveUI"
    s.version       = "2.9.0"
    s.summary       = "BJLiveUI SDK."
    s.description   = "BJLiveUI SDK for iOS."
    
    s.homepage      = "https://www.baijiayun.com/"
    s.license       = "MIT"
    s.author        = { "MingLQ" => "minglq.9@gmail.com" }
    
    s.platform      = :ios, "10.0"
    s.ios.deployment_target = "10.0"
    
    s.source        = {
        :git => "https://github.com/jonkerit/liveFrameWorks.git",
        :tag => s.version.to_s
    }
        
    s.requires_arc = true
    
    # use <"> but not <"> for #{s.name} and #{s.version}
    s.pod_target_xcconfig = {
        "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES", # requies both `user_target_xcconfig` and `pod_target_xcconfig`
        "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) BJLIVEUI_NAME=#{s.name} BJLIVEUI_VERSION=#{s.version}",
        "CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED" => "NO",
        "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64"
    }
    s.user_target_xcconfig = {
        "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES" # requies both `user_target_xcconfig` and `pod_target_xcconfig`
    }
    
    s.default_subspecs = ["static.source"]

    s.subspec "static.source" do |ss|
        ss.public_header_files = [
            "surface/**/BJLiveUI.h",
            "surface/**/BJLScRoomViewController.h",
            "surface/**/BJLOverlayViewController.h",
            "surface/**/BJLOverlayContainerController.h",
            "interactive/**/BJLIcRoomViewController.h"
        ]
        ss.source_files  = ["surface/**/*.{h,m}", "interactive/**/*.{h,m}"]
        ss.resource_bundles = {
            "BJLSurfaceClass" => ["bundles/BJLSurfaceClass/**/*.*"],
            "BJLInteractiveClass" => ["bundles/BJLInteractiveClass/**/*.*"],
            "BJLiveUIMedia" => ["bundles/like.mp3"]
        }
        ss.frameworks = ["CoreGraphics", "Foundation", "CoreServices", "Photos", "PhotosUI", "SafariServices", "UIKit", "WebKit", "SpriteKit"]
        ss.dependency "BaijiaYun/BJLiveCore",                          "~> 2.10.0"
        ss.dependency "QBImagePickerController",                       "~> 3.0"
    end
    
end
