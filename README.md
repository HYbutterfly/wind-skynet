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


### QueryState 死锁问题
```
wind.query() 用来查询 state 时可能发生死锁问题
比如 一个请求 先后 query(stateA) query(stateB), 另一个请求  query(stateB) query(stateA)
2个请求就可能一直互相等待

thread1 : A B
thread2 : B A

解决方案：
	一旦形成死锁, 按请求时间优先原则, 慢的请求释放已锁定的状态并返回错误, worker 收到错误后，则回滚操作(择机重新执行)

比如匹配的例子:
	T1: START_MATCH 	P1, MACTH_QUEUE, P2 P3
	T2: CACNEL_MATCH	P2, MATCH_QUEUE

	T1 在获取P2的时候发现P2已被T2锁定
		session = locked[P2]
		req = request[session]	-- {time:123, locked_names:{P2}, waiting:{MATCH_QUEUE}}
		进而发现 P2 在等 MATCH_QUEUE, 互相等待, 形成死锁
		T2 是后来的，所以 T2 被作废, 解锁P2 req = {time:123},
		T2: err = wind.query(xxx), if err: retry(), 复用之前的 session, 这样再与后面请求形成死锁则有了时间优势
```





### Test (Linux)
```
0. 系统预先安装好lua5.4, git
1. git clone https://github.com/HYbutterfly/wind-ltask wind
2. 进入 wind, git clone https://github.com/cloudwu/skynet.git, 进入skynet编译
3. 在wind文件夹下, ./start.sh
4. 另开一个窗口, 进入 wind, lua client.lua 开启测试客户端, 看见登录成功后 可以 输入 bet 等指令(see client.lua)
```