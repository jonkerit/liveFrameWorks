
echo
echo "### package"
pod package BJLiveUI.podspec \
    --embedded \
    --no-mangle \
    --exclude-deps \
    --spec-sources=http://git.baijiashilian.com/open-ios/BJLiveUI.git,https://github.com/CocoaPods/Specs.git \
    --verbose $args

echo "完成"
