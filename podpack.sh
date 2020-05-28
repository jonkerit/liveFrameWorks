
echo
echo "### package"
pod package BJLiveUI.podspec \
    --embedded \
    --no-mangle \
    --exclude-deps \
    --spec-sources=https://git.baijiashilian.com/open-ios/specs.git,https://github.com/CocoaPods/Specs.git \
    --verbose $args

echo "完成"
