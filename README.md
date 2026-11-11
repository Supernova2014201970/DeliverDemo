# ImageMagick ARVO 基线（上游提交 `13ffeab`，2018-01-16）交付包

一套可离线复现的 ImageMagick 漏洞基准：68 条 ARVO 案例、两个源码节点
（漏洞存在 / 全部修复）、每条案例的 PoC，以及**一个**复现入口
——手写驱动 `hand_repro.cc`（6 个二进制）。

两个节点都是**真实上游提交**，镜像里只是给它们各打了一个 tag 方便引用：

| ref | 提交 | `git describe --match '7.*'` | 作者日期 |
| --- | --- | --- | --- |
| `vuln` | `13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a` | `7.0.7-21-82-g13ffeab` | 2018-01-16 |
| `fixed` | `8239e79ee4c8cc34034838eefe4f34bab02c5fc7` | `7.0.7-27-24-g8239e79` | 2018-03-20 |

`fixed` 是 `vuln` 之后的第 665 个提交，包含全部 62 个 `fix_commit`。
镜像构建时只做 `git tag -f vuln <sha>` / `git tag -f fixed <sha>`：没有 apply、
没有合成 commit、没有补丁文件，`git log` / `git blame` / `git show` / `git diff`
全都落在上游历史上。

交付集里没有任何 fuzz 产物：不编 `encoder_<coder>_fuzzer`、不链 libFuzzer 运行时。
包内**也没有任何 `.patch` 文件**（`payload/patches/`、`image/refs/` 都已删除），
修复视图就是上游自己的 `git diff vuln fixed`。

> **版本号更正**：`13ffeab` **不是** tag `7.0.7-22`，而是 `7.0.7-21-82-g13ffeab`
> （2018-01-16）。tag `7.0.7-22` 是 `b11a66975b900b3eb524360588edb15506290004`
> （2018-01-22），比 `vuln` 晚 6 天，两者不是同一个提交。

一个包，两样东西：

| 产物 | 体积 | 作用 |
| --- | --- | --- |
| 源码部分（`payload/`、`scripts/`、`image/`、`reports/`、本文与 `MANIFEST.md`） | 约 1.1 MB | 可审计、可 diff：PoC、清单、脚本、报告、构镜像的 Dockerfile |
| `im-arvo-2018-01-16.tar`（+ `.sha256`） | **1.38 GB** | 离线可用的成品镜像，`docker load` 即得；`docker images` 显示的 5.41 GB 是**解压后**大小 |

所以整包 1.38 GB，其中 99.9% 是那个 tar。如果只需要源码（自己重建镜像），
单独取除 `im-arvo-2018-01-16.tar*` 之外的部分即可，约 1.1 MB。
每个文件的字节数与 SHA256 见 `MANIFEST.md`。

```bash
sha256sum -c im-arvo-2018-01-16.tar.sha256
docker load -i im-arvo-2018-01-16.tar
docker run -it --security-opt seccomp=unconfined im-arvo:2018-01-16
```

镜像层本身已按 gzip 存储，所以 `.tar` 已经是压缩态；再套 `zstd` 只省 0.01 GB
（实测 1.38 → 1.37），因此不再提供 `.tar.zst`。

> 包里带 1.38 GB 的二进制文件，不适合进 git——放制品库或网盘，仓库里只留
> `deliver/*` 除 tar 外的部分，或者用 Git LFS。

基础镜像在 Dockerfile 里按 **digest** 钉死
（`n132/arvo:42518038-vul@sha256:fce885bd…`），从源码包重建也不会随上游重打 tag 而漂移。

---

## 1. 包里有什么

```
deliver/
├── README.md                     本文
├── MANIFEST.md                   交付件清单（含 SHA256）
├── payload/                      → 打进镜像的 /payload（1.0 MB，无补丁）
│   ├── vulnerabilities.json      68 条漏洞清单（位置/CWE/描述/代码片段/修复说明）
│   ├── vulnerabilities.csv       同上，表格版（由 json 渲染）
│   ├── vulnerabilities.md        同上，人读版（由 json 渲染，附修复片段）
│   ├── cases.tsv                 脚本用的对照组（每行一条案例，9 列）
│   └── pocs/<localId>/poc        68 个 PoC 原始文件（合计 680.8 KiB）
├── scripts/                      → 打进镜像的 /opt/imdt（也是 PATH 的一部分）
│   ├── lib.sh                    公共函数（ref 解析、sanitizer profile、运行、判定）
│   ├── build-san.sh              插桩构建（修前/修后同一套，只差 --tree）+ 手写复现器
│   ├── build-plain.sh            无插桩构建 + 手写复现器 /out/plain-<tree>/repro
│   ├── hand_repro.cc             唯一复现入口（运行时选 coder，复刻 harness 契约）
│   ├── verify.sh                 验证一个节点并产出报告
│   └── imdt                      命令入口：build-before/after、verify-before/after
├── image/
│   ├── Dockerfile                构建镜像（只打两个 tag，不 apply 任何补丁）
│   └── build-image.ps1           构建镜像的一行包装
└── reports/                      实测报告
    ├── before/verify-vuln.{md,json}
    ├── after/verify-fixed.{md,json}
    └── after/cleanliness.md      "clean" 的逐条解释（23/7/38）
```

镜像 `im-arvo:2018-01-16` 里额外包含：

```
/src/imagemagick      git 仓库（完整上游历史，389 个上游 tag + 本包 2 个）
                        vuln  = 13ffeab…  7.0.7-21-82-g13ffeab  2018-01-16
                        fixed = 8239e79…  7.0.7-27-24-g8239e79  2018-03-20
/opt/imdt             上面 scripts/ 的内容（PATH 已包含该目录，可直接 `imdt ...`）
/out                  6 个手写复现器 /out/hand-<profile>-<tree>/repro（共 102 MB）
/work                 空；重新构建时装到 /work/<profile>-<tree>（插桩）、
                      /work/plain-<tree>（无插桩）
```

`/out` 自带 6 个预编译复现器（2 树 × 3 sanitizer），验证不需要现场编译。
`/out/plain-<tree>/repro`（无插桩版）不在镜像里，由 `imdt build-before|build-after` 现编。

补丁的粒度是**上游提交**，不是案例：68 条案例对应 62 个唯一 `fix_commit`
（`e8be814f` 覆盖 5 条，`60cb93d0`、`78eaf41a` 各覆盖 2 条）。这 62 个提交全在
`fixed` 的历史里，要逐条看某个案例被哪次提交、改了哪些行：

```bash
git -C /src/imagemagick show <fix_commit>          # 上游提交本身，含作者/日期/消息
git -C /src/imagemagick log --oneline -- <file>     # 某文件的上游提交序列
```

或读 `payload/vulnerabilities.json` 的 `patch.upstream_commit` / `patch.files` /
`patch.lines_added`。

---

## 2. 快速开始

```bash
# 1) 构建镜像（自带编译，约 6 分钟；不需要任何预编译产物）
docker build -f deliver/image/Dockerfile -t im-arvo:2018-01-16 deliver

# 2) 起容器（MSan 需要 seccomp=unconfined，其余 sanitizer 也用得到）
docker run -dit --name imarvo --security-opt seccomp=unconfined im-arvo:2018-01-16

# 3) 验证两个节点（报告默认写到 /opt/imdt/reports/before|after）
docker exec -it imarvo imdt verify-before --no-build
docker exec -it imarvo imdt verify-after  --no-build
```

`imdt verify-*` 不带 `--no-build` 时会先自己调 `build-before` / `build-after`
（从空 `/work` 全量重编，实测 3 分 45 秒；`/out` 里已有复现器时另说，见第 4 节）。

预期结果（`verify.sh` 的判定：出现 `SUMMARY:` 记 CRASH，否则 CLEAN）：

| 命令 | 报告 | 总计 | 结论 |
| --- | --- | --- | --- |
| `imdt verify-before --no-build` | `reports/before/verify-vuln.md` | `crash=68 clean=0` | 68 条全部复现崩溃（实测 12 s） |
| `imdt verify-after --no-build` | `reports/after/verify-fixed.md` | `crash=0 clean=68` | 68 条全部不再崩溃（实测 2 s；但见 `reports/after/cleanliness.md`） |

> `clean=68` 不等于"68 条都被这次修复修好了"：`fixed` 是 665 个提交之后的上游现状，
> 只有 23 条能归因到针对它的修复。详见第 4 节与 `reports/after/cleanliness.md`。

只跑一套 sanitizer：

```bash
docker exec -it imarvo imdt verify-before --no-build --san address      # 只跑 ASan 那 20 条
docker exec -it imarvo verify.sh --tree vuln --san memory --report /tmp/rep/mem
```

> `verify.sh` **不构建**，只跑现成产物；产物缺失会直接报错并告诉你该跑哪条 build 命令。
> 构建默认复用 `/out`（提交号未变即跳过），`imdt build-* --force` / `build-san.sh --force` 才重编。

---

## 3. 漏洞分布

68 条案例的构成如下。数字由 `payload/cases.tsv`、`payload/vulnerabilities.json` 和
`payload/pocs/*/poc` 现算，每张表都带合计，可自行加总对照 68。

### 按格式（coder）

`format` 与 `coder` 一一对应，共 33 个取值：

| 格式 | 条数 | 格式 | 条数 | 格式 | 条数 |
| --- | --- | --- | --- | --- | --- |
| `MIFF` | 9 | `MVG` | 7 | `WPG` | 5 |
| `PALM` | 3 | `PDB` | 3 | `VIFF` | 3 |
| `DCM` | 2 | `EPS` | 2 | `EPSI` | 2 |
| `GIF` | 2 | `HDR` | 2 | `PCX` | 2 |
| `PICT` | 2 | `PSD` | 2 | `SUN` | 2 |
| `TIM` | 2 | `TXT` | 2 | `CIN` | 1 |
| `DPX` | 1 | `DXT5` | 1 | `G3` | 1 |
| `MAC` | 1 | `MAT` | 1 | `PCDS` | 1 |
| `PES` | 1 | `PNM` | 1 | `PS` | 1 |
| `RLE` | 1 | `SCR` | 1 | `SIX` | 1 |
| `SIXEL` | 1 | `WBMP` | 1 | `XCF` | 1 |
| **合计** | **68** | | | | |

`MIFF`(9)、`MVG`(7)、`WPG`(5) 和 `PALM`/`PDB`/`VIFF`(各 3) 六项就占 30 条；33 个格式里
16 个只出现 1 次，前三个格式合计 21 条（31%）。

### 按 sanitizer

| `cases.tsv` 的 `sanitizer` | `vulnerabilities.json` 的 `sanitizer` | 条数 |
| --- | --- | --- |
| `address` | `asan` | 20 |
| `memory` | `msan` | 47 |
| `undefined` | `ubsan` | 1 |
| **合计** | | **68** |

MSan 47 条（69%）、ASan 20 条（29%）、UBSan 只有 1 条（`42518038`）。这是**案例数**，
不是二进制数：6 个复现器每个 coder 走运行时参数，一个 coder 可以带多条案例。

### 按崩溃类型

| 家族 | `type.crash_type` 取值 | 条数 | CWE（`type.cwe`） |
| --- | --- | --- | --- |
| Use-of-uninitialized-value | `Use-of-uninitialized-value` | 47 | `CWE-457` |
| Heap-buffer-overflow WRITE | `WRITE 8`×3、`WRITE {*}`×3、`WRITE 4`×2 | 8 | `CWE-787` |
| Heap-buffer-overflow READ | `READ 1`×5、`READ 4`×1 | 6 | `CWE-125` |
| Stack-buffer-overflow | `READ 1`、`READ {*}`、`WRITE 1`、`WRITE 8` 各 1 | 4 | `CWE-121`×2、`CWE-125`×2 |
| UNKNOWN | `UNKNOWN WRITE` | 1 | `CWE-787` |
| SEGV | 无（`UNKNOWN WRITE` 在重放时表现为 `SEGV caused by a WRITE`） | 0 | — |
| 其他 | `Index-out-of-bounds`、`Negative-size-param` 各 1 | 2 | `CWE-129`、`CWE-787` |
| **合计** | | **68** | |

47 条（69%）是未初始化读（只对应 `CWE-457`）；其余 21 条是 ASan/UBSan 的越界与非法参数：
堆写 8、堆读 6、栈 4、`UNKNOWN WRITE` 1、`Index-out-of-bounds` 1、`Negative-size-param` 1。
`type.crash_type` 里没有字面量 `SEGV`，那一类只在重放输出里以 `SEGV caused by a WRITE` 出现。

### 按修复点所在目录

| 目录（`code_snippet.file`） | 条数 | 说明 |
| --- | --- | --- |
| `coders/` | 44 | 各格式解码器 |
| `MagickCore/` | 19 | 共享核心（像素存取、属性/配置文件、quantum 导入等） |
| `Magick++/fuzz/` | 5 | fuzz harness 本身（`utils.cc` 的资源上限） |
| 其他 | 0 | — |
| **合计** | **68** | |

44 条（65%）的修复点在 `coders/`，19 条（28%）在 `MagickCore/`，5 条在 harness 里。
另有 42 条的 `code_snippet.file` 与 `location.file`（ARVO 记录的 `#0` 所在文件）不是同一个文件，
所以"修复点在哪"和"崩溃点在哪"两张分布表不会一样。

### 共享修复提交

| `fix_commit` | 覆盖案例 | 条数 |
| --- | --- | --- |
| `e8be814f` | `42518038` G3、`42518649` PALM、`42518894` WPG、`42519338` WPG、`42519771` TIM | 5 |
| `60cb93d0` | `42523502`、`42533154`（均 VIFF） | 2 |
| `78eaf41a` | `42525647`、`42525669`（均 MIFF） | 2 |
| 其余 59 个提交 | 每条案例一个提交 | 59 |
| **合计** | **68 条案例 → 62 个唯一提交** | **68** |

68 条案例只对应 62 个唯一 `fix_commit`：3 个提交各修多条，其余 59 个各修 1 条
（5+2+2+59=68，3+59=62）。`e8be814f` 那 5 条的修复写在 `Magick++/fuzz/utils.cc` 里
（`ResourceLimits::width(2048)`），**不是产品代码缺陷**，做漏洞研究时应剔除或降权
（与第 7 节第 2、3 条一致）。

### PoC 体积

| 指标 | 字节 | 案例 |
| --- | --- | --- |
| 最小 | 1 B | `42522269`（WBMP）、`42532777`（SCR），均 MSan 条 |
| 中位数 | 95 B | 排序后第 34/35 位为 81 B、95 B |
| 最大 | 655,416 B | `42519182`（SUN，ASan） |
| **68 个文件合计** | **697,128 B（680.8 KiB）** | 与 `MANIFEST.md` 的 680.8 KiB 一致 |

58 条不超过 1 KiB、28 条不超过 64 B，超过 1 KiB 的只有 10 条；最大的 `42519182` 一条就占总体积的 94%，
次大的两条是 `42519760`（PES，9,060 B）与 `42533954`（PCDS，6,144 B），去掉最大一条后其余 67 条平均约 620 B。

**这套分布说明什么**：修复点 65% 落在 `coders/`、28% 落在 `MagickCore/`，说明这套基准压的是
"畸形输入进各格式解码器"的边界处理，而不是某个核心算法的深层逻辑；47 条是 MSan 的未初始化读，
其余 21 条才是越界与非法参数，验证主体在 MSan 一侧。33 个格式里 16 个只出现 1 次、前三个格式占 31%，
按格式切分做统计时样本极不均衡，只适合按"解码器 / 核心 / harness"这类粗分组来读；
PoC 侧同样是长尾，中位数 95 B，最大一条 655 KB。

---

## 4. 两个节点与"构建脚本是不是一样的"

**两个节点都是真实上游提交**，镜像只给它们打 tag：

```bash
git tag -f vuln  13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a
git tag -f fixed 8239e79ee4c8cc34034838eefe4f34bab02c5fc7
```

没有 apply、没有 commit、没有补丁文件；`git log` / `git blame` / `git show` / `git diff`
都是上游历史。构建时（`docker build` 的 Run 层与最后的 sanity 层）会直接校验
`git rev-parse vuln fixed` 等于上面两个 SHA，并且 `git merge-base --is-ancestor vuln fixed` 成立。

### 怎么证明它真的是上游提交

```bash
$ git -C /src/imagemagick log --no-walk --format='%H %ci %s' vuln fixed
8239e79ee4c8cc34034838eefe4f34bab02c5fc7 2018-03-20 19:44:04 -0400 https://mail.google.com/mail/#inbox/162426a98e65ed90
13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a 2018-01-16 12:27:52 +0100 Fixed build for VS2013.

$ git -C /src/imagemagick describe --tags --match '7.*' vuln fixed
7.0.7-21-82-g13ffeab
7.0.7-27-24-g8239e79

$ git -C /src/imagemagick rev-list --count vuln..fixed
665

$ git -C /src/imagemagick diff --stat vuln fixed | tail -1
 391 files changed, 9377 insertions(+), 14285 deletions(-)

$ git -C /src/imagemagick show --stat --oneline e8be814f    # 一条 fix_commit，上游原样
e8be814 Limit image maximum width and height to 2048 pixels
 Magick++/fuzz/utils.cc | 2 ++
 1 file changed, 2 insertions(+)

$ git -C /src/imagemagick tag -l | wc -l                    # 389 个上游 tag + vuln + fixed
391
```

`git describe --match '7.*'` 里的 `--match` 是必须的：不加它，`git describe` 会把本包新加的
`vuln` / `fixed` 两个 tag 当成最近的 tag 答出来（`describe --tags vuln` 打印的就是 `vuln`）。
镜像里的 git 是 2.7.4，没有 `--exclude`。

### "clean" 到底意味着什么（scheme D 的硬限制）

`imdt verify-after` 得到 `crash=0 clean=68`，但 `fixed` 是 `vuln` 之后 665 个提交的上游现状，
不是"基线 + 62 个补丁"的理想对照。68 条"没崩"里只有 **23 条**能归因到针对它的那次修复：

| 分类 | 条数 | 含义 |
| --- | --- | --- |
| decoded / 未崩 | 23 | 走过了会被修复的代码路径，在 `fixed` 上不再崩——**唯一可归因**的一组 |
| `width or height exceeds limit` | 7 | 被 `Magick++/fuzz/utils.cc` 的 `ResourceLimits::width(2048)`/`height(2048)`（`e8be814f`）拦下；harness 级上限，不是产品代码修复 |
| 更早的解析校验拒绝 | 38 | 665 个提交里新增/收紧的校验（`improper image header`、`unexpected end-of-file`、`CorruptWBMPimage` …）在到达脆弱代码之前就退出 |
| **合计** | **68** | |

这 23/7/38 是用一个只多打印一句被吞掉的 `Magick::Exception.what()` 的诊断驱动，在
`fixed` 树上逐条跑出来的；逐条明细（localId / coder / sanitizer / 分类 / 异常文本）在
`reports/after/cleanliness.md`。`fixed` 侧报告的 `SUMMARY` 列全是 `—`，正是因为这个
driver 和 `hand_repro.cc` 一样吞掉异常、只留 `SUMMARY:` 作为崩溃信号。

再往下压一层：`fixed` 上那 7 条之所以"干净"，靠的是 `-DHARNESS_FIXED_LIMITS`
（`build-san.sh` / `build-plain.sh` 对 `fixed` 树自动加）。**不带**这个宏时，`fixed` 上仍有
**2 条**会崩：

| localId | coder | sanitizer | 不带上限时的表现 |
| --- | --- | --- | --- |
| `42518038` | G3 | undefined | UBSan 报告 |
| `42518894` | WPG | memory | MSan 报告 |

因为这两条案例的修复本身就写在 harness 里（`e8be814f` 的 `width/height` 上限），产品代码
没有对应改动。也就是说：**scheme D 下 `crash=0 clean=68` 的成立依赖 harness 级上限，
而真正能归因到具体修复的只有 23 条**——这是本方案的固有代价，不是可以调掉的参数。

### 构建脚本是同一套

只有一个插桩构建脚本 `build-san.sh`，差别只在 `--tree`：

```bash
build-san.sh --tree vuln  --san address   # 等价于 git checkout vuln  && 编译插桩
build-san.sh --tree fixed --san memory    # 等价于 git checkout fixed && 编译插桩
build-san.sh --tree vuln  --san all       # 三个 profile 各编一次（imdt build-* 用的就是它）
```

`--tree` 只接受 `vuln|fixed`，提交号由 `git rev-parse <tree>^{commit}` 现解，脚本里没有硬编码
SHA；每次构建都会把解出来的完整 SHA 和上游版本号打出来：

```
tree fixed = 8239e79ee4c8cc34034838eefe4f34bab02c5fc7 (7.0.7-27-24-g8239e79)
building fixed/address at 8239e79ee4c8cc34034838eefe4f34bab02c5fc7 (7.0.7-27-24-g8239e79)
```

它做五步：`git checkout -f --detach <tree>` + `git clean -xffdq` → `./configure --prefix=/work/<profile>-<tree>`
（configure 用不带插桩的 flag；插桩只在 make 阶段注入，好让 configure 的探测程序能跑）
→ `make -j` + `make install`（带该 profile 的 sanitize flags）→ 用同一个 prefix、同一套插桩把
手写复现器 `hand_repro.cc` 编成 `/out/hand-<profile>-<tree>/repro`（`fixed` 树额外加
`-DHARNESS_FIXED_LIMITS`，`memory` 额外加 `-L/usr/msan/lib`）→ `nm` 检查插桩符号并写
`BUILD_INFO`（提交号、flags、耗时）。

**它不编 fuzz 靶子，也不编 libFuzzer 运行时。** 一次构建只产出一个可执行文件。
树构建已存在且提交号未变时跳过重编；只缺复现器时只补编那一个；`--force` 强制全部重建。

**无插桩构建** `build-plain.sh --tree vuln|fixed [--force]`：同一行 configure、同一条
`make -j`，只是不带任何 sanitizer flag；装到 `/work/plain-<tree>`，并把 `hand_repro.cc`
编成 `/out/plain-<tree>/repro`。它结尾会把两个 ref 都打出来并明说二者不是同一个提交：

```
vuln  13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a  7.0.7-21-82-g13ffeab  2018-01-16
fixed 8239e79ee4c8cc34034838eefe4f34bab02c5fc7  7.0.7-27-24-g8239e79  2018-03-20
vuln and fixed are different upstream commits: fixed is 665 commits after vuln
```

除 `--tree` / `--san` / `--force` / `--dry-run` 外只有一个开关：

| 开关 | 作用 |
| --- | --- |
| `--out <dir>` | 产物（`repro` + `BUILD_INFO`）改写到 `<dir>`，install prefix 同步变成 `/work/prefix-<basename>`；不碰 `/out` |

六套构建产物各自独立、从不合并：

| 目录 | 插桩 | 节点 | 镜像内大小 |
| --- | --- | --- | --- |
| `/out/hand-address-vuln/repro` | ASan | 13ffeab（漏洞存在） | 21 MB |
| `/out/hand-undefined-vuln/repro` | UBSan | 13ffeab（漏洞存在） | 8.1 MB |
| `/out/hand-memory-vuln/repro` | MSan | 13ffeab（漏洞存在） | 22 MB |
| `/out/hand-address-fixed/repro` | ASan | 8239e79（全部修复） | 21 MB |
| `/out/hand-undefined-fixed/repro` | UBSan | 8239e79（全部修复） | 8.2 MB |
| `/out/hand-memory-fixed/repro` | MSan | 8239e79（全部修复） | 23 MB |

**为什么不合并**：`-fsanitize=address,undefined` 编进同一个二进制时，UBSan 会在
`fixed` 树上报本来就存在、与本次修复无关的 UB（如 `coders/sixel.c`、`MagickCore/string.c`
里的老问题），看起来像"没修好"。

**构建耗时**（墙钟，镜像内，每个 profile，含 configure + make + install）：
vuln address 62 s、vuln undefined 43 s、vuln memory 74 s；fixed address 63 s、
fixed undefined 44 s、fixed memory 75 s——镜像构建时串行跑完 6 个 profile，合计 361 s
（数字来自镜像内 `/out/hand-*/BUILD_INFO`）。
`imdt build-before` 从空 `/work` 全量重建（3 个插桩 profile + 无插桩）实测 3 分 45 秒
（225 s：address 64 s、undefined 43 s、memory 75 s、无插桩 42 s）。

**MSan 链接**：镜像默认的 libc++（`/usr/local/lib/libc++.a`）没有 MSan 插桩，
构建时用 `-L/usr/msan/lib` 链上插桩版（该归档含 223 个 `__msan_` 符号）。
否则任何 `std::string` / `iostream` 操作都会在正常输入上报
use-of-uninitialized-value，C++ 复现器在 MSan 下看起来是"坏的"。

两个节点定义：

| ref | 内容 | 提交 |
| --- | --- | --- |
| `vuln` | 上游 2018-01-16 的提交（`7.0.7-21-82-g13ffeab`） | `13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a` |
| `fixed` | 上游 2018-03-20 的提交（`7.0.7-27-24-g8239e79`），晚 665 个提交，含全部 62 个 `fix_commit` | `8239e79ee4c8cc34034838eefe4f34bab02c5fc7` |

两者之间的差异就是那 665 个提交，随时可查：

```bash
git -C /src/imagemagick log --oneline vuln..fixed | wc -l     # 665
git -C /src/imagemagick diff --stat vuln fixed | tail -1      # 391 files changed, +9377 −14285
```

要重编修复态，直接用这个节点：

```bash
build-san.sh --tree fixed --san address --out /work/check --force
/work/check/repro MVG /payload/pocs/42524289/poc   # 不再出现 SUMMARY:
```

---

## 5. 单个案例怎么验

只有一个入口：手写驱动，coder 走命令行参数。

```bash
# 漏洞存在的节点：期望出现 SUMMARY:
ASAN_OPTIONS=detect_leaks=0 /out/hand-address-vuln/repro MVG /payload/pocs/42524289/poc

# 全部修复的节点：期望没有 SUMMARY: 行
ASAN_OPTIONS=detect_leaks=0 /out/hand-address-fixed/repro MVG /payload/pocs/42524289/poc

# 无插桩版（build-plain.sh 产出）：没有 sanitizer，很多越界直接段错误（exit 139）
/out/plain-vuln/repro MVG /payload/pocs/42524289/poc
```

`hand_repro.cc` 是 harness 契约的手写复刻（见第 9 节），不是 fuzz 靶子：
没有 libFuzzer 的 `main()`、没有 `-timeout` / `-rss_limit_mb` 参数，也没有
corpus 语义——第二个参数就是单个 PoC 文件。MSan profile 需要 `setarch x86_64 -R`
（脚本内部已加），容器需要 `--security-opt seccomp=unconfined`。

要追某条案例在 `fixed` 上为什么不崩，用 `reports/after/cleanliness.md` 的分类，再对着
上游提交看：`git -C /src/imagemagick show <fix_commit>`。

> 注意 `build-san.sh` / `build-plain.sh` 都会 `git clean -xffdq`，手工改过的工作区要先复制走。

---

## 6. 判定标准与报告

每条案例在 `cases.tsv` 里带期望值（9 列，无补丁列）：

| 列 | 含义 |
| --- | --- |
| `localId` | ARVO 案例编号 |
| `coder` | ImageMagick coder 名（大写），运行时传给复现器 |
| `target` | ARVO 记录里的 OSS-Fuzz 靶子名（`encoder_<coder>_fuzzer`），仅供对照；本包不构建它 |
| `sanitizer` | 该条案例用哪套插桩（`address` / `undefined` / `memory`） |
| `expect_frame` | ARVO 记录里的 `#0` 函数名（报告里由 `SUMMARY:` 全文体现） |
| `expect_kind` | ARVO 的 `crash_type` 片段（`heap-buffer-overflow` 等） |
| `poc` | PoC 路径（相对 `/payload`） |
| `after_expect` | 恒为 `no-crash`：每条案例在 `fixed` 树上都应无崩溃 |
| `fix_commit` | 修这条案例的上游提交（提交本身就在镜像的 git 历史里） |

`verify.sh` 的判定只有一条规则：**运行输出里出现 `SUMMARY:` 行就是 CRASH，否则 CLEAN**。
不看 exit code——ImageMagick 的解码失败会走异常路径，exit 仍为 0；也不做函数名比对，
因为 ARVO 的措辞在重放时会变（`UNKNOWN WRITE` 重放成 `SEGV caused by a WRITE`），
`SUMMARY:` 全文原样写进报告，人读或机读都能自己比。

期望的总计：

| tree | 期望 | 说明 |
| --- | --- | --- |
| `vuln`（`13ffeab`） | `crash=68 clean=0` | 68 条全部复现崩溃 |
| `fixed`（`8239e79`） | `crash=0 clean=68` | 68 条全部不再崩（其中仅 23 条可归因，见第 4 节） |

`verify.sh` 按这个期望判 PASS/FAIL，命中 exit 0，否则 exit 1。报告两份：

- `verify-<tree>.md`：元信息（tree/commit/entry/sanitizer/时间戳）+ 每行一条案例
  （localId、coder、sanitizer、format、result、SUMMARY 全文）+ `crash=N clean=M` + verdict；
- `verify-<tree>.json`：同样的内容，机器可读（`totals` / `expected` / `verdict` / `results[]`）。

报告落在 `--report` 指定的目录（默认 `reports/before`、`reports/after`，相对 `/opt/imdt`）。
重新生成并取回源码包：

```bash
docker exec -it imarvo imdt verify-before --no-build --report /tmp/rep/before
docker exec -it imarvo imdt verify-after  --no-build --report /tmp/rep/after
docker cp imarvo:/tmp/rep/before deliver/reports/before
docker cp imarvo:/tmp/rep/after  deliver/reports/after
```

`format` 列是 ARVO 记录里的图像格式（`payload/vulnerabilities.json` 的 `format`），
和 `coder` 通常相同，但两者语义不同（编码器名 vs 图像格式），所以分列保留。

`reports/after/cleanliness.md` 是第三份、人读的报告：它不用 `SUMMARY:` 判定，而是逐条
记录 `fixed` 树上的读/写结果与被吞掉的异常文本，把 68 条"clean"拆成 23/7/38，
并列出不带 `-DHARNESS_FIXED_LIMITS` 时仍然崩的 2 条。

---

## 7. 已知限制

1. **本交付集为 68 条**；上游数据里另有 1 条（`42519948`）因修复依赖 7.0.7-23 才引入的
   `Magick::ResourceLimits::listLength`、且修复落在 fuzz harness 里，未纳入本交付集。
2. **scheme D 的核心限制**：`fixed` 是真实上游提交，晚 `vuln` 665 个提交，所以
   `crash=0 clean=68` 里只有 **23 条**能归因到针对它的那次修复；7 条被 harness 级
   `width/height(2048)` 上限（`e8be814f`）拦下，38 条在更早的解析校验处就被拒。
   拿它做"修复有效性"评测时，只有那 23 条是可用的正样本，另外 45 条应剔除或单列。
3. **7 条"clean"依赖 harness 级上限**：不带 `-DHARNESS_FIXED_LIMITS` 时，`fixed` 上
   `42518038`（G3，UBSan）与 `42518894`（WPG，MSan）仍会崩——这两条的"修复"本身就写在
   `Magick++/fuzz/utils.cc` 里，产品代码没有对应改动。
4. **没有任何补丁文件**：`payload/`、`image/` 里都没有 `.patch`。修复视图是
   `git -C /src/imagemagick diff vuln fixed`（上游 665 个提交的全部差异），
   单条修复是 `git show <fix_commit>`（上游提交原样）。逐条的
   `patch.{upstream_commit,status,files,lines_added,lines_removed}` 仍在
   `vulnerabilities.json` 里，供交叉核对。
5. **判据是"崩溃是否出现"**，不是行为断言。能证明"这个输入在这棵树上触发这个漏洞"，
   不能证明"漏洞只在这一处"；`clean` 也不等于"这条修复生效"（见第 2 条）。
6. **MSan 容器必须 `--security-opt seccomp=unconfined`**，且脚本内部已对 MSan 加
   `setarch x86_64 -R`（老 clang 6 MSan 在新内核 + ASLR 下会假崩）。
7. **CWE 是按崩溃类型推导的**，OSS-Fuzz issue 本身没有 CVE/CWE 字段。
8. **验证跑在现成产物上**：`verify.sh` 本身不构建；镜像 `/out` 里的 6 个复现器由
   Dockerfile 在构建期编出，`imdt build-before|build-after` 在提交号未变时直接复用
   （缺 `/work` 前缀时会重编），`--force` 才强制重编，结果可复现。
9. **没有 fuzz 运行时**：交付集不编 `encoder_<coder>_fuzzer`，也不编/不链 libFuzzer
   （`/src/libfuzzer` 与 `/work/engine-*` 都不再用到）。因此报告里的
   `SUMMARY:` 来自手写驱动的调用路径，而不是 fuzz 靶子的；两者的等价性靠第 9 节的
   契约复刻保证，而不是靠同一个二进制。
10. **手写复现器只复刻契约，不是产品代码入口**：`hand_repro.cc` 照抄 harness 的
    `magick(coder)` + `fileName("<coder>:")` + `read`/`write` + 吞掉 `Magick::Exception`，
    以及 `utils.cc` 的字面限制。`fixed` 树上它要额外带 `-DHARNESS_FIXED_LIMITS`
    （镜像里由 `build-san.sh` / `build-plain.sh` 自动加），否则那 2 条仍会崩。

---

## 8. 交付件是否完整

| 你要的东西 | 在哪 |
| --- | --- |
| 漏洞列表 | `payload/vulnerabilities.json`（+ csv/md），68 条 |
| 基础镜像（含源码、两个真实提交、poc、复现器） | `im-arvo:2018-01-16`，`vuln`/`fixed` 两个 tag + `/payload` + `/out` |
| 复现器（6 个，可直接跑） | 镜像内 `/out/hand-<profile>-<tree>/repro`（Dockerfile 构建期编出） |
| 构建脚本（修前/修后是否一样） | `scripts/build-san.sh`，**同一套**，只差 `--tree vuln\|fixed` |
| 无插桩构建 + 手写复现器 | `scripts/build-plain.sh` + `scripts/hand_repro.cc` → `/out/plain-<tree>/repro` |
| 修复前验证 | `imdt verify-before` → `verify.sh --tree vuln`（跑全部 PoC → 68 条全崩）→ `reports/before/` |
| 修复后验证 | `imdt verify-after` → `verify.sh --tree fixed`（跑全部 PoC → 68 条全不崩）→ `reports/after/` |
| "clean" 的成因 | `reports/after/cleanliness.md`（23/7/38 + 2 条无上限仍崩） |
| 单条案例的修复 diff | `git -C /src/imagemagick show <fix_commit>`（上游提交原样） |

---

## 9. 复现器为什么等价（harness 契约，而不是靶子）

交付集只有一个复现入口：`scripts/hand_repro.cc` → `/out/hand-<profile>-<tree>/repro`。
它不是 fuzz 靶子的重新包装，而是把靶子的契约**手抄**了一遍；等价性来自逐条对齐
`Magick++/fuzz/encoder_fuzzer.cc` + `Magick++/fuzz/utils.cc` 做的事：

| harness 做的事 | `hand_repro.cc` 的做法 |
| --- | --- |
| 编译期 `-DFUZZ_IMAGEMAGICK_ENCODER=<CODER>` 固定格式 | 运行期 `argv[1]`，`image.magick(coder)` |
| `image.fileName("<coder>:")`（带冒号，按 coder 选读入器） | 同左，冒号照抄 |
| `image.read(Magick::Blob(data, size))` | 同左：PoC 字节原样进 `Blob` |
| `image.write(&blob, coder)` 回写（编码路径也覆盖） | 同左 |
| `catch (Magick::Exception)` 后正常返回，解析失败不算崩溃 | 同左（read/write 各自吞掉） |
| `utils.cc`：`SecurityPolicy::maxMemoryRequest(256e6)`、`ResourceLimits::memory(1e9)` | 同左，字面数值一致 |
| `utils.cc`（`fixed` 树，`e8be814f`）：`ResourceLimits::width(2048)` / `height(2048)` | `-DHARNESS_FIXED_LIMITS` 分支，同样两行 |

差异只有一处：coder 从命令行来，而不是编译期常量，所以一个二进制能跑完整个 profile
（68 条 → 6 个二进制，而不是 80 个靶子）。sanitizer 输出、调用链、资源上限、异常语义
都与靶子一致——`/out` 里没有 libFuzzer，也就不用为"运行时本身要不要插桩"操心
（这是早先一轮在 `fixed/memory` 上出 47 条假失败的根因）。

`vuln` 与 `fixed` 的资源上限并不相同：`fixed` 的历史里有 `e8be814f`，多了
`width/height(2048)`。靶子从检出树里白拿这个差异，手写驱动得自己追——这就是
`-DHARNESS_FIXED_LIMITS` 的由来；少了它，`fixed` 树在 `42518038`（G3）、
`42518894`（WPG）上照崩，因为这两条修的是 harness，不是产品缺陷。

实测（镜像 `im-arvo:2018-01-16` 内，68 条，`reports/` 里就是这两份）：

| tree | 结果 | 结论 |
| --- | --- | --- |
| `vuln` = `13ffeab` | `crash=68 clean=0` | 68 条全部复现崩溃 |
| `fixed` = `8239e79` | `crash=0 clean=68` | 68 条全部不再崩（仅 23 条可归因，见第 4 节） |
