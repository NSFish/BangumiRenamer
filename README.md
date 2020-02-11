# BangumiRenamer

### Usage

从 Wikipedia 或者百度百科等处获得番剧剧集列表，保存为 [source.txt](https://github.com/NSFish/BangumiRenamer/blob/master/TestCase/source.txt)（或者其他喜欢的名字）。

然后创建 [pattern.txt](https://github.com/NSFish/BangumiRenamer/blob/master/TestCase/pattern.txt)，用正则表达式标识出文件名中剧集的集数，比如

> Ep.[0-9]{3}
>
> 对应的是 [NAOKI-Raws&倉吉観光協会] 名探偵コナン／Part.11-Vol.1 Ep.287 「工藤新一NYの事件（推理編）」 (DVDRip x264 AC3 Chap) 这样的剧集名。

最后执行

```shell
bangumi-renamer -s /Path/to/source.txt -d /Path/to/seriesDirectory -p /Path/to/pattern.txt
```

bangumi-renamer 将根据集数来逐一重命名 seriesDirectory 中的视频和字幕文件。