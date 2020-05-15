
echo
echo "### package"
pod package BJLiveUI.podspec \
    --embedded \
    --no-mangle \
    --exclude-deps \
    --spec-sources=https://github.com/jonkerit/liveFrameWorks.git,https://github.com/CocoaPods/Specs.git \
    --verbose $args

echo "完成"
