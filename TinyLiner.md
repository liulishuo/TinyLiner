# TinyLiner

+++++++++

TinyLiner是一套抽象精简的埋点数据组织方案，针对坑位埋点的弊端，做了定向优化，力求升级改造成本最小化。

## TinyLiner针对谁

+++++++

传统坑位埋点有两个主要问题：

1. 坑位之间无关联，回溯链路困难。且为了标识埋点上报的位置，需要传递魔鬼参数，破坏封装；
2. 每个坑位要携带完整的数据，导致数据重复上报；

TinyLiner针对以上两点做了优化。

## TinyLiner包含哪些概念

+++++

只有两个概念，所有埋点事件根据是否持续，抽象为点和线

- Line

  持续事件，在时间轴上展开为有向线段

- Point

  瞬时事件，一定从属于某条线

## TinyLiner概念图

+++++

### 抽象

![未命名文件(18)](./assets/未命名文件(18).png)



### 结构

![未命名文件(19)](./assets/未命名文件(19).png)

## TinyLiner特点

+++

### 轻量化

- 高度抽象，仅有两个专有概念，学习成本极低
- 剥离了所有埋点均要重复上传的数据，组成随时间演变的“上下文”，所有埋点将有链接自己所属的“上下文”，而不是直接携带完整数据

### 链路可追踪

- 用户从第一次启动开始的所有埋点均形成可追溯的链路



## 使用TinyLiner

+++++

### 开始监控

```swift
TinyLiner.shared.sessionStart()
```

### 结束监控

```swift
TinyLiner.shared.sessionEnd()
```

### 打点（记录瞬时事件）

```swift
TinyLiner.shared.point("事件ID", ext: ["xxxKey": "xxxValue"])
```

### 开始划线（记录持续事件）

```swift
TinyLiner.shared.line("事件ID")
```

### 结束划线（记录持续事件）

```swift
TinyLiner.shared.lineDone("事件ID")
```

### 导出埋点数据

```swift
TinyLiner.shared.dump { [weak self] logs in
    guard let logs = logs else {
        return
    }
    /// finsh you work here
 }
```

### 清空埋点数据

```
TinyLiner.shared.clean()
```

### 切换上下文

```
TinyLiner.shared.changeContext("key1", "key2", "key3...")
```



## DEBUG

使用TinyLiner自带的用图形界面

<img src="./assets/Simulator Screenshot - iPhone 14 Pro - 2023-11-14 at 18.34.09.png" alt="Simulator Screenshot - iPhone 14 Pro - 2023-11-14 at 18.34.09" style="zoom: 25%;" /><img src="./assets/Simulator Screenshot - iPhone 14 Pro - 2023-11-14 at 18.33.36.png" alt="Simulator Screenshot - iPhone 14 Pro - 2023-11-14 at 18.33.36" style="zoom: 25%;" /><img src="./assets/Simulator Screenshot - iPhone 14 Pro - 2023-11-14 at 18.33.58.png" alt="Simulator Screenshot - iPhone 14 Pro - 2023-11-14 at 18.33.58" style="zoom: 25%;" />

## 默认约定

- “@” 表示line间前后链路关系

  例如：6s8dase@4a3bdc@广告页@首页

  表示：[上次冷启动的会话]-->[本次冷启动的会话]-->广告页-->首页

- “.” 表示point对line的从属关系

  例如：广告页.userDetail

  表示：在广告页展示期间，发生了id为userDetail的打点事件
