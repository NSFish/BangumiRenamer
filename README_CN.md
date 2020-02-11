# BangumiRenamer

将下载来的番剧文件名规范化，也适用于电视剧剧集等。

![](https://raw.githubusercontent.com/NSFish/TuChuang/master/pic/bangumi-renamer.gif)

### 安装

推荐使用 homebrew
```shell
brew tap NSFish/homebrew-tap
brew install bangumi-renamer
```

或在 Release 页面自行下载。

### 使用方法

从维基百科或[萌娘百科](https://zh.moegirl.org/zh-hans/Mainpage)等处获得番剧剧集列表，保存为 [source.txt](https://github.com/NSFish/BangumiRenamer/blob/master/TestCase/source.txt)（或者其他喜欢的名字）。

然后创建 [pattern.txt](https://github.com/NSFish/BangumiRenamer/blob/master/TestCase/pattern.txt)，用正则表达式标识出文件名中剧集的集数，比如

>[NAOKI-Raws&倉吉観光協会] 名探偵コナン／Part.11-Vol.1 Ep.287 「工藤新一NYの事件（推理編）」 (DVDRip x264 AC3 Chap) 
>
> 对应
>
> Ep.[0-9]{3}

最后执行

```shell
bangumi-renamer -s /Path/to/source.txt -d /Path/to/bangumiDirectory -p /Path/to/pattern.txt
```

bangumi-renamer 将根据集数来逐一重命名 bangumiDirectory 中的视频和字幕文件。