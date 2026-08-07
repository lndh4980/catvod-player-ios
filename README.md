# CatVodPlayer - 影视仓 iOS 播放器

支持影视仓/CatVod JSON 配置格式的 iOS 原生播放器。

## 功能特性

✅ **直播源播放**
- 支持 m3u/m3u8 格式
- 支持 txt 格式
- 自动解析频道列表

✅ **点播站点**
- 展示所有站点列表
- 支持搜索过滤
- 显示站点类型和 API 信息

✅ **配置管理**
- 自定义配置地址
- 自动保存配置
- 一键加载/清除

✅ **播放器**
- 基于 VLCKit
- 支持多种视频格式
- 支持画面比例调整

## 安装方式

### TrollStore 安装（推荐）

1. 下载 IPA 文件
2. 使用 TrollStore 安装
3. 支持 iOS 16.0+

### 配置地址

支持标准的影视仓 JSON 格式，例如：

```
https://qist.wyfc.qzz.io/fty.json
```

## 配置格式

```json
{
  "spider": "./jar/fan.txt;md5;xxx",
  "wallpaper": "https://example.com/wallpaper.jpg",
  "sites": [
    {
      "key": "site1",
      "name": "站点名称",
      "type": 3,
      "api": "csp_xxxGuard",
      "searchable": 1,
      "quickSearch": 1
    }
  ],
  "lives": [
    {
      "name": "直播源名称",
      "type": 0,
      "url": "https://example.com/live.m3u",
      "playerType": 2
    }
  ]
}
```

## 技术栈

- Swift 5.9
- SwiftUI
- VLCKit 3.6.0
- iOS 16.0+

## 编译

需要 macOS + Xcode 15.0+

```bash
# 安装 XcodeGen
brew install xcodegen

# 生成项目
xcodegen generate

# 编译
xcodebuild -project CatVodPlayer.xcodeproj -scheme CatVodPlayer -configuration Release
```

## 许可证

MIT License

## 注意事项

- 本应用仅供学习交流使用
- 请勿用于非法用途
- 使用者需自行承担法律责任
