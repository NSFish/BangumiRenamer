# BangumiRenamer

### Usage

First, get bangumi series list from places like Wikipedia and save it as [source.txt](https://github.com/NSFish/BangumiRenamer/blob/master/TestCase/source.txt), or any other name you prefer.

Then create [pattern.txt](https://github.com/NSFish/BangumiRenamer/blob/master/TestCase/pattern.txt) and specify the series number in filename using regex, for example

> [NAOKI-Raws&倉吉観光協会] 名探偵コナン／Part.11-Vol.1 Ep.287 「工藤新一NYの事件（推理編）」 (DVDRip x264 AC3 Chap)
>
> Ep.[0-9]{3}

Finally, go

```shell
bangumi-renamer -s /Path/to/source.txt -d /Path/to/bangumiDirectory -p /Path/to/pattern.txt
```

bangumi-renamer will do the trick to rename all media files according to the source.txt you provide.