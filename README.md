# LuaGameFramework

基于cocos2d-x-3.15.1 May.27 2017版本

根据项目需求进行了裁剪和扩展，具体修改参见[ChangeLog](./CHANGELOG.md)

## 使用方法

`setup_game01.bat`用于初始化`client`目录下的`game01`，bat脚本内部可以设置文件夹名和所使用的tag。

将`setup_game01.bat`放在相关项目的`client`下，运行bat会自动就行`git clone`和`git checkout`到相关tag。

复制`LuaGameFramework\application`到`client`目录下并进行相关项目的定制和开发。

运行`client\game01\run_game.bat`即可开启游戏客户端。

## 目录用途

`MyLuaGame` 存放的是公用目录。

`application` 在各自项目有各自的目录，这里放的是template。

`application`下有个`build.bat`用来设定各项目相关src路径和预处理。

## 注意事项

### 项目中的开发提交

由于是符号链接，所以在game01里运行是没问题的，但提交是无法检测到符号链接文件夹里的变动，所以修改需要进入到git目录。

具体参见[开发说明](https://git.tianji-game.com/tjgame/LuaGameFramework/wiki/LuaGameFramework%E5%BC%80%E5%8F%91%E8%AF%B4%E6%98%8E)

### 项目运行

`application`下新增目录，需要在`build.bat`脚本中增加相关创建符号链接语句。

bat默认的工作目录是`run_game.bat`所处目录，运行`run_game.bat`时会自动调用`build.bat` 。

```bash
cd src
mklink /d app ..\..\application\src\app
```

