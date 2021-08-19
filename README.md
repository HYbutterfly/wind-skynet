# wind-skynet
[ltask版本](https://github.com/HYbutterfly/wind-ltask)
[skynet版本](https://github.com/HYbutterfly/wind-skynet)
```
wind server 有2个版本, ltask 定位于技术探索版, skynet版本 则是稳定版, 商业项目可以用skynet版本,
玩的话可以用ltask版本
```

### 概述
```
有关具体设计思路等，可以移步 ltask 版本查看, 这边的文档慢慢补充
```


### Test (Linux)
```
0. 系统预先安装好lua5.4, git
1. git clone https://github.com/HYbutterfly/wind-ltask wind
2. 进入 wind, git clone https://github.com/cloudwu/skynet.git, 进入skynet编译
3. 在wind文件夹下, ./start.sh
4. 另开一个窗口, 进入 wind, lua client.lua 开启测试客户端, 看见登录成功后 可以 输入 bet 等指令(see client.lua)
```