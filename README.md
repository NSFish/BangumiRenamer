# BangumiRenamer

[中文 README](https://github.com/NSFish/BangumiRenamer/blob/master/README_CN.md)

Organize your downloaded bangumi series files, also works for tv-shows.

![](https://raw.githubusercontent.com/NSFish/TuChuang/master/pic/bangumi-renamer.gif)

### Installation

It's recommended to use homebrew
```shell
brew tap NSFish/homebrew-tap
brew install bangumi-renamer
```

Or you can download the executable file at the release page.

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