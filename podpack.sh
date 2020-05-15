
echo
echo "### package"
pod package BJLiveUI.podspec \
    --embedded \
    --no-mangle \
    --exclude-deps \
    --spec-sources=git@git.baijiashilian.com:ios/specs.git,https://github.com/CocoaPods/Specs.git \
    --verbose $args

echo "完成"
