## 直播 UI SDK 源码集成 & 自定义修改

### 1、 git clone UI SDK 至 工程同级目录

- 示例工程为 BJLiveUITest.

```ruby
git clone http://git.baijiashilian.com/open-ios/BJLiveUI.git
```

![image](https://img.baijiayun.com/0baijiatools/18701f175efb47acb5b8dcf0d79b83f0/clone.png)

### 2、 clone的UI SDK 可使用 git 跟踪。

- 示例中使用 SourceTree 工具来进行，直接拖入即可，这样可以跟踪到 SDK 的版本更新，再自行决定是否同步到本地。

![image](https://img.baijiayun.com/0baijiatools/92fe078ce108a4f003f5756051993da4/git.png)

![image](https://img.baijiayun.com/0baijiatools/d06d57b323642d07cf624603192ff57e/git1.png)

![image](https://img.baijiayun.com/0baijiatools/9e16d32f11c573a1f52cd28108d04327/git2.png)

### 3、 在BJLiveUITest 工程目录下创建 Podfile

- 内容如下：

```ruby
  source 'https://github.com/CocoaPods/Specs.git'
  source 'http://git.baijiashilian.com/open-ios/specs.git'
  
  platform :ios, '9.0'
  target 'BJLiveUITest' do
      
  pod 'BJLiveUI/static.source', :path => '../BJLiveUI/'
      
   # 用于动态引入 Framework，避免冲突问题
   script_phase \
   :name => '[BJLiveCore] Embed Frameworks',
   :script => 'Pods/BJLiveCore/frameworks/EmbedFrameworks.sh',
   :execution_position => :after_compile
   # 用到了点播回放 SDK 时需要加上
   script_phase \
   :name => '[BJVideoPlayerCore] Embed Frameworks',
   :script => 'Pods/BJVideoPlayerCore/frameworks/EmbedFrameworks.sh', # for remote BJVideoPlayerBase
   :execution_position => :after_compile
   # 用于清理动态引入的 Framework 用不到的架构，避免发布 AppStore 时发生错误，需要写在动态引入 Framework 的 script 之后
   script_phase \
   :name => '[BJLiveBase] Clear Archs From Frameworks',
   :script => 'Pods/BJLiveBase/script/ClearArchsFromFrameworks.sh "BJHLMediaPlayer.framework" "BJYIJKMediaFramework.framework"',
   :execution_position => :after_compile
            
    end
```

- 其中“:path => '../BJLiveUI/' ”指定的是 UI SDK 相对于工程目录的路径，static.source 表示开源集成。指定本地相对路径集成，就不用担心自定义的修改在下次执行 pod update 的时候被覆盖掉。

### 4、 在工程目录下执行 pod install

- 成功之后可以使用 Xcode 打开，看到如下内容说明开源集成已成功：

![image](https://img.baijiayun.com/0baijiatools/47e8ca3c55332366b4591dac686ab38e/staticsource.png)

### 5、 自定义修改：修改UI SDK的源文件

- 这里以 BJLiveUI.h 文件为例。

![image](https://img.baijiayun.com/0baijiatools/576b4c8387bbfe73ee652d0d2d02e4d1/staticsouce1.png)

- 本地的修改推荐用 SourceTree 进行管理，同时也可以跟踪到远程仓库的修改。

![image](https://img.baijiayun.com/0baijiatools/c81659def80550ab7f89bcf154b68c4d/sourcetree.png)

- 因为 pod 集成的是本地路径的 UI SDK，所以不用担心本地的修改被覆盖，点播、回放 SDK 同理。


### 6、仓库管理
- 我们的 git 迁到国内的域名了，无法使用 fork 的方式。可以新建一个自己的 remote 仓库，添加到本地的 SDK 上，这样就既能管理自己的修改，又能跟踪到我们的更新了。

![image](https://img.baijiayun.com/0baijiatools/3bffecf00b321dea0f2004a30d98271a/sourcetree2.png)



