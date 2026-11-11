# cleanliness — `fixed` 树上 68 条"没崩"是怎么来的

`reports/after/verify-fixed.md` 的结论是 `crash=0 clean=68`。这份文件解释那 68 条
"clean"：**只有 23 条**能归因到针对它的那次修复，其余 45 条是 `fixed` 跨了 665 个提交
带来的旁证。

## 1. 怎么测出来的

| 项 | 值 |
| --- | --- |
| 树 | `fixed` = `8239e79ee4c8cc34034838eefe4f34bab02c5fc7`（`7.0.7-27-24-g8239e79`，2018-03-20） |
| 构建 | `build-plain.sh --tree fixed`（无插桩，装到 `/work/plain-fixed`，56 s），诊断驱动链接同一套静态库 |
| 资源上限 | 与 `scripts/hand_repro.cc` 一致：`maxMemoryRequest(256e6)`、`memory(1e9)`、`width(2048)`、`height(2048)` |
| 案例集 | `payload/cases.tsv` 全部 68 条（2 树 × 3 sanitizer 的复现器与案例的 sanitizer 列一一对应） |
| 判据 | `read` 是否抛异常、异常文本是什么；`write` 是否成功 |

诊断驱动和 `scripts/hand_repro.cc` 的**唯一**差别：它不吞 `Magick::Exception`，而是把
`what()` 打出来，并把 `read` / `write` 两个阶段分开报告。下面表格的 evidence 列就是这些
输出（已去掉 `Magick:` 前缀和 `@ error/<file>/<func>/<line>` 位置后缀）。

> 这是 plain 构建、不带 sanitizer，所以它回答的是"这个 PoC 有没有走到会被修复的那段代码"，
> 而不是"sanitizer 报不报"。sanitizer 判定仍以 `reports/after/verify-fixed.md` 为准。

## 2. 汇总：23 / 7 / 38

| 分类 | 条数 | 含义 |
| --- | --- | --- |
| **decoded** — 解码成功，未崩 | **23** | 走到了会被修复的代码路径，在 `fixed` 上不再崩。**唯一可归因**的一组（其中 19 条 write 也成功，4 条 write 报 `no encode delegate`，即解码器可写方向本就不存在） |
| **limit** — `width or height exceeds limit` | **7** | 被 `Magick++/fuzz/utils.cc` 的 `ResourceLimits::width(2048)`/`height(2048)`（`e8be814f`）拦下。harness 级上限，不是产品代码修复 |
| **parser** — 更早的解析校验拒绝 | **38** | 665 个提交里新增/收紧的校验在到达脆弱代码之前就抛异常退出 |
| **合计** | **68** | |

`parser` 那 38 条的异常文本分布：

| 异常文本（`Magick:` 后） | 条数 |
| --- | --- |
| `improper image header` | 13 |
| `unexpected end-of-file` | 9 |
| `No image was loaded` | 5 |
| `non-conforming drawing primitive definition` | 5 |
| `unrecognized color` | 2 |
| `pixels are not authentic`（TXT） | 1 |
| `not enough pixel data`（XCF） | 1 |
| `CorruptWBMPimage`（WBMP） | 1 |
| `CorruptImage`（PES） | 1 |
| **合计** | **38** |

## 3. 被 `width/height(2048)` 上限拦下的 7 条

| localId | coder | sanitizer | `fix_commit` | 备注 |
| --- | --- | --- | --- | --- |
| `42518038` | G3 | undefined | `e8be814f` | 修复本身就在 harness 里 |
| `42518649` | PALM | memory | `e8be814f` | 同上 |
| `42518894` | WPG | memory | `e8be814f` | 同上 |
| `42519338` | WPG | memory | `e8be814f` | 同上 |
| `42519771` | TIM | memory | `e8be814f` | 同上 |
| `42519416` | SIXEL | address | `614d7b14` | 案例的修复在 `coders/`，但 PoC 在 `fixed` 上先撞同一上限 |
| `42519749` | SIX | address | `8e5432bd` | 同上 |

5 条的 `fix_commit` 就是 `e8be814f`；另外 2 条（`42519416` SIXEL、`42519749` SIX）
的修复在别处，但它们的 PoC 在 665 个提交之后也先撞上这个上限，所以同样只能算"没崩"，
不能算"该修复生效"。

## 4. 去掉 `-DHARNESS_FIXED_LIMITS` 后仍然崩的 2 条

`fixed` 侧的"全干净"依赖这个宏；不带它时下面 2 条会崩（sanitizer 构建，实测）：

| localId | coder | sanitizer | 不带宏时的输出 |
| --- | --- | --- | --- |
| `42518038` | G3 | undefined | `MagickCore/compress.c:836:28: runtime error: index 39 out of bounds for type 'const HuffmanTable [28]'` → `HuffmanEncodeImage` ← `WriteFAXImage` ← `WriteImage` |
| `42518894` | WPG | memory | `SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/cache.c:3362:11 in WritePixelCacheRegion` |

复现方式（镜像内）：

```bash
build-san.sh --tree fixed --san undefined --force     # 或 --san memory
P=/work/undefined-fixed
clang++ -O1 -gline-tables-only -fno-omit-frame-pointer -stdlib=libc++ -std=c++11 \
  -fsanitize=undefined -fno-sanitize-recover=undefined \
  -I$P/include/ImageMagick-7 /opt/imdt/hand_repro.cc -o /tmp/nolim-undefined \
  -DMAGICKCORE_HDRI_ENABLE=1 -DMAGICKCORE_QUANTUM_DEPTH=16 \
  $P/lib/libMagick++-7.Q16HDRI.a $P/lib/libMagickWand-7.Q16HDRI.a \
  $P/lib/libMagickCore-7.Q16HDRI.a -lpthread -lm
UBSAN_OPTIONS=print_stacktrace=1 /tmp/nolim-undefined G3  /payload/pocs/42518038/poc
setarch x86_64 -R env MSAN_OPTIONS=print_stats=1 /tmp/nolim-memory WPG /payload/pocs/42518894/poc
```

同样的两条，用镜像自带的 `/out/hand-undefined-fixed/repro` 和
`/out/hand-memory-fixed/repro`（带宏）跑，输出为空。

## 5. 逐条明细（68 条）

| localId | coder | sanitizer | 分类 | evidence（`fixed`，plain 构建） |
| --- | --- | --- | --- | --- |
| `42518038` | G3 | undefined | **limit** | width or height exceeds limit `G3:' |
| `42518438` | CIN | address | **parser** | unexpected end-of-file 'CIN:': No such file or directory |
| `42518471` | MIFF | memory | **parser** | improper image header `MIFF:' |
| `42518560` | TXT | memory | **parser** | pixels are not authentic `TXT:' |
| `42518649` | PALM | memory | **limit** | width or height exceeds limit `PALM:' |
| `42518894` | WPG | memory | **limit** | width or height exceeds limit `WPG:' |
| `42519182` | SUN | address | **decoded** | read ok → write ok, 36 bytes |
| `42519338` | WPG | memory | **limit** | width or height exceeds limit `WPG:' |
| `42519416` | SIXEL | address | **limit** | width or height exceeds limit `SIXEL:' |
| `42519504` | EPSI | address | **parser** | No image was loaded. |
| `42519749` | SIX | address | **limit** | width or height exceeds limit `SIX:' |
| `42519760` | PES | address | **parser** | CorruptImage `PES:' |
| `42519771` | TIM | memory | **limit** | width or height exceeds limit `TIM:' |
| `42519915` | MIFF | memory | **parser** | improper image header `MIFF:' |
| `42520316` | EPS | address | **parser** | No image was loaded. |
| `42520493` | DXT5 | address | **parser** | improper image header `DXT5:' |
| `42520871` | EPS | memory | **parser** | No image was loaded. |
| `42520948` | DCM | memory | **parser** | unexpected end-of-file 'DCM:': No such file or directory |
| `42520971` | PDB | memory | **parser** | improper image header `PDB:' |
| `42521159` | TXT | memory | **decoded** | read ok → write ok, 405 bytes |
| `42521170` | WPG | memory | **decoded** | read ok → write: no encode delegate for this image format `WPG' |
| `42521270` | PCX | memory | **decoded** | read ok → write ok, 898 bytes |
| `42521591` | MVG | address | **parser** | non-conforming drawing primitive definition `url(#' |
| `42521846` | PICT | memory | **parser** | improper image header `PICT:' |
| `42521858` | PALM | memory | **parser** | unexpected end-of-file 'PALM:': No such file or directory |
| `42521880` | VIFF | memory | **decoded** | read ok → write ok, 1108 bytes |
| `42522269` | WBMP | memory | **parser** | CorruptWBMPimage `WBMP:' |
| `42522303` | WPG | memory | **parser** | improper image header `WPG:' |
| `42522513` | MVG | memory | **parser** | non-conforming drawing primitive definition `I333' |
| `42522869` | PALM | memory | **decoded** | read ok → write ok, 16336 bytes |
| `42523358` | PNM | memory | **decoded** | read ok → write ok, 10 bytes |
| `42523502` | VIFF | memory | **parser** | unexpected end-of-file 'VIFF:': No such file or directory |
| `42523812` | DPX | memory | **decoded** | read ok → write ok, 9216 bytes |
| `42523868` | MAT | memory | **decoded** | read ok → write ok, 192 bytes |
| `42523879` | PSD | address | **parser** | improper image header `PSD:' |
| `42524289` | MVG | address | **parser** | non-conforming drawing primitive definition `ARC' |
| `42524701` | XCF | memory | **parser** | not enough pixel data `XCF:' |
| `42525613` | PSD | memory | **decoded** | read ok → write ok, 196 bytes |
| `42525647` | MIFF | memory | **parser** | improper image header `MIFF:' |
| `42525669` | MIFF | memory | **parser** | improper image header `MIFF:' |
| `42525880` | HDR | address | **decoded** | read ok → write ok, 4635 bytes |
| `42526335` | GIF | memory | **decoded** | read ok → write ok, 119 bytes |
| `42526424` | EPSI | address | **parser** | No image was loaded. |
| `42526757` | PS | address | **parser** | No image was loaded. |
| `42527322` | PICT | memory | **parser** | improper image header `PICT:' |
| `42527699` | GIF | memory | **decoded** | read ok → write ok, 274 bytes |
| `42527789` | MIFF | address | **parser** | improper image header `MIFF:' |
| `42528177` | MIFF | memory | **parser** | improper image header `MIFF:' |
| `42528200` | PCX | memory | **decoded** | read ok → write ok, 236 bytes |
| `42528610` | SUN | memory | **decoded** | read ok → write ok, 64 bytes |
| `42529799` | MIFF | memory | **decoded** | read ok → write ok, 403 bytes |
| `42530943` | MVG | address | **parser** | non-conforming drawing primitive definition `�' |
| `42530977` | HDR | memory | **parser** | unexpected end-of-file 'HDR:': No such file or directory |
| `42531054` | MIFF | memory | **decoded** | read ok → write ok, 288 bytes |
| `42531466` | DCM | address | **parser** | unexpected end-of-file 'DCM:': No such file or directory |
| `42532777` | SCR | memory | **parser** | improper image header `SCR:' |
| `42533154` | VIFF | memory | **parser** | unexpected end-of-file 'VIFF:': No such file or directory |
| `42533821` | MIFF | memory | **decoded** | read ok → write ok, 378 bytes |
| `42533954` | PCDS | memory | **decoded** | read ok → write ok, 788480 bytes |
| `42533966` | MAC | memory | **decoded** | read ok → write: no encode delegate for this image format `MAC' |
| `42534188` | WPG | memory | **decoded** | read ok → write: no encode delegate for this image format `WPG' |
| `42534522` | TIM | memory | **decoded** | read ok → write: no encode delegate for this image format `TIM' |
| `42534621` | PDB | memory | **parser** | unexpected end-of-file 'PDB:': No such file or directory |
| `42534921` | MVG | address | **parser** | unrecognized color `(' |
| `42535088` | MVG | address | **parser** | unrecognized color `(' |
| `42535232` | RLE | memory | **parser** | unexpected end-of-file `RLE:' |
| `42535688` | PDB | memory | **decoded** | read ok → write ok, 4456 bytes |
| `42537011` | MVG | address | **parser** | non-conforming drawing primitive definition `' |

## 6. 怎么读这份分类

- **`decoded` 的 23 条**是"修复有效性"评测里唯一可用的正样本：PoC 真的解出来了，
  而没有崩。
- **`limit` 的 7 条**证明不了产品代码修复：真正起作用的是 harness 里的
  `ResourceLimits::width/height(2048)`。
- **`parser` 的 38 条**是 PoC 已经过时：`fixed` 比 `vuln` 晚 665 个提交，新校验先拒了
  输入，`vuln` 上崩溃的那段代码根本没被碰到。
- 想要"只差 62 个补丁"的理想对照，需要把补丁叠在同一棵基线上（合成节点 —— 本方案
  scheme D 明确放弃）。当前方案用两个真实上游提交，代价就是上面这 23/7/38 的分布，
  以及不带 `-DHARNESS_FIXED_LIMITS` 时仍然崩的 2 条。
