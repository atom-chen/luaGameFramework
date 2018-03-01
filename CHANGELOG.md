# Change Log

- cocos2d-x-3.15.1

- 2017-7-19
  - remove `libbullet` and `librecast` in win32 proj
  - disable `CC_USE_PHYSICS`, `CC_USE_3D_PHYSICS`,`CC_USE_NAVMESH` in `ccConfig.h` and lua-binding
  - modify about `tolua` tool 
  - re-gen lua bindings code

- 2017-7-20
  - compile simulator
  - build android apk (proj.andorid had libsimulator, it need be removed in release)
  - copy `ymextra`
  - copy `AssetManager` and `Appdelegate`
  - build win32 proj ok
- 2017-7-21
  - copy `updater`
  - copy `lua_print`
- 2017-7-25
  - modify `class` similar with shuma
  - [ ] `kCompanyShortName`,  `kCompanyName` and `_toLuaPwd` changed, the packer need update
  - [ ] iPad ration < 1.34 change with (1136, 852, FIXED_WIDTH)
  - [x] `class` no `__tostring`?
- 2017-7-26
  - search cocos2dx modified code in shuma, use svn log
  - [x] ~~spine fixed mem in `extension.c`~~

> https://github.com/EsotericSoftware/spine-runtimes/blob/3.6/CHANGELOG.md 
>
> spine runtime v2.5 improve it. test and benchmark it. no copy old now.

- 2017-7-26
  - spine runtime upgrade to [github branch 3.6](https://github.com/EsotericSoftware/spine-runtimes/tree/3.6) 1535906511875a5f7a560bef349bca34ab7ef894
    - [ ] android project need upgrade
    - [ ] ios project need upgrade
    - [x] almost are new feature in spine, upgrade lua bindings
- 2017-7-27
  - support pvr.ccz, png searching in order, when `TextureCache.addImage ` png.
  - make android project ok
  - disabled AR
  - [x] remove AR
  - [ ] ~~remove 3d~~, `Partical University` use `Srpite3D`
  - [x] remove cocosbuilder
  - [x] remove tiff and webp
- 2017-7-28
  - v136 deps for luajit on iOS
- 2017-7-31
  - `widgetFromJsonFile`不用来json路径，方便做语言适配
  - 制订一些UI存放规范
  - NodeEvent一些尾递归优化
- 2017-8-2
  - 迁移lua相关辅助库
  - `lua_cocos2dx_spine_SkeletonAnimation_setAnimation`添加成功返回值
  - 读取cocos sutdio，对layout进行锚点计算
- 2017-8-3
  - 增强bind功能
    - onTouch 
- 2017-8-4
  - 接入网易云捕
- 2017-8-21
  - 移入editor
  - `Widget::hitTest`手动简单实现
  - 去掉`luaval_to_int32`的error提示，主要针对addChild
- 2017-8-23
  - 一些规范命名。FinalSDK、GameApp
  - 独立cache、translate管理
- 2017-8-27
  - idler和idlers相关bind机制完善
  - finalsdk条件OC调用
- 2017-8-31
  - [ ] ViewBase的close机制，维护UI链
  - [ ] Node退出时，所关联的idler需要remove listener！！！
  - [x] editor内置Lua热更新失效
- 2017-9-6
  - editor Node定位增加img路径显示
- 2017-11-16
  - 增加handlers，为了应用层去除view对parent依赖
  - 增加调试用tag log
- 2017-11-20
  - `LuaMinXmlHttpRequest::_sendRequest`完整处理非200返回时的异常处理
- 2017-11-23
  - 增加对ipad屏幕适配
- 2018-1-1
  - 增加win32下iup库支持，可开发native窗口程序用于工具链和编辑器
- 2018-2-24
  - 迁移到git进行开发和管理
  - TODO将放置到issue里，这里CHANGELOG作为版本节点记录

