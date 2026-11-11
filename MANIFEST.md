# 交付件清单

一个包，两样东西：源码（约 1.1 MB）+ 成品镜像 tar（`im-arvo-2018-01-16.tar`，
1,477,459,456 字节 = 1.38 GB，`docker load` 后 `docker images` 显示 5.41 GB 是解压后大小）。
镜像内含 6 个手写复现器，无 fuzz 靶子、无 libFuzzer。

包内**没有任何补丁文件**（`payload/patches/`、`image/refs/` 都已删除），也没有预编译产物
目录（`prebuilt/` 已删除，复现器由 Dockerfile 在构建期编出）。

## 1. 镜像内节点（两个真实上游提交，只打了 tag）

| ref | 提交 | `git describe --match '7.*'` | 日期 | 内容 |
| --- | --- | --- | --- | --- |
| `vuln` | `13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a` | `7.0.7-21-82-g13ffeab` | 2018-01-16 | 漏洞存在的上游提交（`Fixed build for VS2013.`） |
| `fixed` | `8239e79ee4c8cc34034838eefe4f34bab02c5fc7` | `7.0.7-27-24-g8239e79` | 2018-03-20 | 上游提交，晚 `vuln` 665 个提交，含全部 62 个 `fix_commit` |

镜像构建时只执行两条命令：`git tag -f vuln 13ffeab…` / `git tag -f fixed 8239e79…`。
没有 `git apply`、没有合成 commit、没有补丁文件；`git log` / `git blame` / `git show` /
`git diff` 全部落在上游历史上，镜像最后的 sanity 层还会校验两个 tag 解析出的 SHA 与
`git merge-base --is-ancestor vuln fixed`。

`vuln..fixed` 差异：391 个文件，+9,377 / −14,285 行——这是 665 个上游提交的**全量**差异，
不是 62 个补丁的和；因此 `fixed` 侧 `crash=0 clean=68` 里只有 23 条可归因
（见 `reports/after/cleanliness.md`）。

镜像内 `/out` 含 6 个手写复现器（`vuln`/`fixed` × `address`/`undefined`/`memory`，
共 102 MB）；`/work` 是空的，重编时装到 `/work/<profile>-<tree>`（插桩）与
`/work/plain-<tree>`（无插桩）。不再有 `encoder_<coder>_fuzzer`，也不再有
`/work/engine-<profile>/libFuzzingEngine.a`。

## 2. 文件清单与校验值

| 文件 | 字节 | SHA256 |
| --- | --- | --- |
| `README.md` | 32,173 | `1b68980bc20ab09ccaf3164ec3776f19dc5358b83a6164ff3a65681b4c0d2863` |
| `MANIFEST.md` | — | —（自引用不入表；校验：`sha256sum MANIFEST.md`） |
| `payload/cases.tsv` | 10,993 | `13952c6cfbe2b4727279628035f5d2a267dd0f1ac80ccbe4cc6f37a11f86d64c` |
| `payload/vulnerabilities.json` | 184,743 | `98881cb9c4e63806fe6425c9ce6e22ff114e518784293996e01ff1379ed0b1dd` |
| `payload/vulnerabilities.csv` | 38,403 | `91f45fd1fb29c4eefcf811eb1dc15ef79bdb65ac20425c11acecb8d75567fa42` |
| `payload/vulnerabilities.md` | 72,413 | `43ce5fccafab103000a4155c3690fbc7cd7b9bf455d656643d720827a0643ebc` |
| `payload/pocs/<localId>/poc` | 68 个文件，697,128 B（680.8 KiB） | 逐条校验：`sha256sum payload/pocs/*/poc` |
| `image/Dockerfile` | 4,090 | `c3bc9977d0cb067820de035c3d1a7755a5cf4d457261fd1245d57c0036b63002` |
| `image/build-image.ps1` | 383 | `88ea65825101d5356970a3505ad8d210ce0bb2b2ddcfd61c858b01fb531433eb` |
| `scripts/lib.sh` | 4,797 | `831abe35056defffa095ddf23d392b406bf9fdf6dc0c8154284a71c4871e2806` |
| `scripts/build-san.sh` | 6,392 | `b7e092e144e35a38f491efd4c9ff5e6c16861a6f00b52777b534578cd9891716` |
| `scripts/build-plain.sh` | 4,271 | `3f478910d7e51569d0004206f6e0987551dc06012891376b06c8f47001a1e1f2` |
| `scripts/hand_repro.cc` | 2,966 | `eaaaeb5eb36184b07525bfc54861a63576328e1e24f79cbe5a2e36b073f96226` |
| `scripts/verify.sh` | 6,901 | `afa251bb879af7f2c5c5e3e3692679b4187a809d87411e9c8352cdc27490515c` |
| `scripts/imdt` | 2,130 | `f57e667aff959d61fed5b55117cf1d52b774fa05356ad42563913baeebec7cbd` |
| `reports/before/verify-vuln.md` | 11,872 | `c02e824b44c96752a818659e72251c749991da4858c01e4a712f4debf2e6b98e` |
| `reports/before/verify-vuln.json` | 16,583 | `ec66e426e26e18e19fb8ef5d652013b2bdc1c7482b32c592e213d5661cdc54d8` |
| `reports/after/verify-fixed.md` | 3,838 | `d07c16c82c596a98ad26d9e13fdd1194b275c064a159d009f4a3e8af326f9955` |
| `reports/after/verify-fixed.json` | 8,480 | `df58f3f8a278cb0613c5878c6965e55989216bae3770c7fe2430b5fcba482e0d` |
| `reports/after/cleanliness.md` | 11,501 | `960f7474d312eae90d2473c917321b105df9c0fba2024a6364dbed3189d57e5a` |
| `im-arvo-2018-01-16.tar` | 1,477,459,456 | `72b8a5ecb95058e19223b2fdf50fd2f47eb64ea396055246a4421b1f8140f29f` |
| `im-arvo-2018-01-16.tar.sha256` | 90 | `8240a54baed0f3af3e3223f14552a33ef36e2b47071837b4f2525fb8e44518cd` |

上表 21 个单文件行 + 1 个聚合行（68 个 PoC）已逐行对着磁盘重算并核对通过。
整包 89 个文件（含本文）：除 `MANIFEST.md` 自身外合计 1,478,579,603 字节，其中源码部分 1,120,057 字节、镜像 tar 1,477,459,456 字节。

```bash
cd deliver
sha256sum README.md payload/cases.tsv payload/vulnerabilities.{json,csv,md} \
          image/Dockerfile image/build-image.ps1 \
          scripts/{lib.sh,build-san.sh,build-plain.sh,hand_repro.cc,verify.sh,imdt} \
          reports/before/* reports/after/*
sha256sum -c im-arvo-2018-01-16.tar.sha256      # 1.38 GB，约 10 秒
```

## 3. 每个交付件的用途

| 交付件 | 解决的问题 |
| --- | --- |
| `payload/vulnerabilities.json` | 68 条漏洞清单：位置、CWE、描述、`code_snippet`（修复前后代码 + diff）、补丁元数据（`upstream_commit`/`status`/`files`/行数，**不含文件路径**）、修复说明、验证状态 |
| 镜像 + `vuln`/`fixed` 两个 tag | 一条命令切到"漏洞存在"或"全部修复"的源码树，无需手工打补丁；两个 tag 都指向真实上游提交 |
| `payload/pocs/` | 68 个 PoC 原始输入（字节原样），脚本按 `cases.tsv` 自动取用 |
| `payload/cases.tsv` | 脚本的对照组（9 列）：每条案例的 coder、sanitizer、期望崩溃点、期望类型、PoC 路径、修复后期望、`fix_commit`；无补丁列 |
| `scripts/build-san.sh` | 唯一插桩构建脚本，`--tree vuln\|fixed` + `--san address\|undefined\|memory\|all` 决定构建哪一套；提交号由 `git rev-parse <tree>` 现解（不硬编码），每次构建打印完整 SHA + 上游版本号；**只产出一个可执行文件**：手写复现器 `hand_repro.cc` → `/out/hand-<profile>-<tree>/repro`（`fixed` 树带 `-DHARNESS_FIXED_LIMITS`，`memory` 带 `-L/usr/msan/lib`）；不编 fuzz 靶子、不编 libFuzzer；另有 `--force` / `--dry-run` / `--out <dir>` |
| `scripts/build-plain.sh` | 无插桩构建：同一行 configure / 同一条 `make -j`，不带任何 sanitizer flag；装到 `/work/plain-<tree>`，把手写复现器编成 `/out/plain-<tree>/repro`；结尾打印 `vuln` / `fixed` 的完整提交、上游版本、日期，并说明 `fixed` 比 `vuln` 晚 665 个提交 |
| `scripts/hand_repro.cc` | 唯一复现驱动：`repro <coder> <poc>` 运行时选 coder，复刻 harness 契约（`magick` + `fileName("<coder>:")` → `read` → `write`，吞 `Magick::Exception`）与 `utils.cc` 的 fuzzing 限制；`-DHARNESS_FIXED_LIMITS` 再加 `width/height(2048)` |
| `scripts/verify.sh` | 验证一个节点并产出报告：`--tree vuln\|fixed`、`--san all\|address\|undefined\|memory`、`--report DIR`；逐条判 CRASH（有 `SUMMARY:`）/ CLEAN，写 `verify-<tree>.md` + `.json`（localId、coder、sanitizer、format、result、SUMMARY 全文、`crash=N clean=M`、verdict）；期望 `vuln` → `crash=68 clean=0`、`fixed` → `crash=0 clean=68`，命中 exit 0。**没有 `--entry`** |
| `scripts/imdt` | 命令入口：`build-before` / `build-after`（切树 → `build-san.sh --san all` → `build-plain.sh`）、`verify-before` / `verify-after`（先构建，可用 `--no-build` 跳过，再 `verify.sh --report reports/before\|after`，透传 `--san`） |
| `reports/before/`、`reports/after/` | 修复前 68 处 crash / 修复后 0 处 crash 的实测报告（手写入口，各 md + json） |
| `reports/after/cleanliness.md` | `fixed` 侧 68 条"clean"的逐条明细与成因（23 decoded / 7 被 `width/height(2048)` 拦下 / 38 被更早的解析校验拒绝），以及不带 `-DHARNESS_FIXED_LIMITS` 时仍崩的 2 条 |

## 4. 交付前的实测记录

在交付镜像 `im-arvo:2018-01-16` 内实测
（`docker run ... --security-opt seccomp=unconfined`），入口是 `imdt`：

| 项 | 结果 |
| --- | --- |
| `imdt verify-before --no-build` | `crash=68 clean=0` → PASS（`reports/before/verify-vuln.md`）；12 s |
| `imdt verify-after --no-build` | `crash=0 clean=68` → PASS（`reports/after/verify-fixed.md`）；2 s |
| `imdt build-before`（从空 `/work` 全量） | 成功，墙钟 **3 min 45 s**（225 s）：address 64 s、undefined 43 s、memory 75 s、无插桩 42 s；结尾打印 `vuln 13ffeab… 7.0.7-21-82-g13ffeab` / `fixed 8239e79… 7.0.7-27-24-g8239e79` / `fixed is 665 commits after vuln` |
| `git -C /src/imagemagick rev-parse vuln fixed` | `13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a` / `8239e79ee4c8cc34034838eefe4f34bab02c5fc7`（两个真实上游提交） |
| `build-san.sh --tree fixed --san address --dry-run` | 打印 `tree fixed = 8239e79…（7.0.7-27-24-g8239e79）`、prefix、CFLAGS、`-DHARNESS_FIXED_LIMITS`、产物路径 |
| `build-san.sh --tree vuln --san address`（已构建） | `already built: /out/hand-address-vuln/repro — use --force to rebuild` |
| 镜像构建（6 个 profile 串行） | 361 s：vuln address 62 s / undefined 43 s / memory 74 s；fixed address 63 s / undefined 44 s / memory 75 s |
| 镜像 | `im-arvo:2018-01-16`，5.41 GB（`docker images` 的 DISK USAGE）；两个 tag 解析到真实 SHA、`merge-base --is-ancestor vuln fixed` 成立、工作区干净，`/out` 下 6 个 `hand-*` 各有一个可执行的 `repro`，`/work` 为空 |
| `fixed` 上不带 `-DHARNESS_FIXED_LIMITS` | `42518038`（G3，UBSan）与 `42518894`（WPG，MSan）仍崩；带宏时两条均静默（详见 `reports/after/cleanliness.md`） |

单条手工复跑：

```bash
ASAN_OPTIONS=detect_leaks=0 /out/hand-address-vuln/repro MVG /payload/pocs/42524289/poc   # 期望 SUMMARY:
ASAN_OPTIONS=detect_leaks=0 /out/hand-address-fixed/repro MVG /payload/pocs/42524289/poc  # 期望没有 SUMMARY:
/out/plain-vuln/repro MVG /payload/pocs/42524289/poc                                      # 无插桩，段错误
```

重建时 `build-san.sh --tree X --san Y` 在提交号未变且 `/work` 前缀还在时会直接跳过，
`--force` 才重编。configure / PerlMagick 的 `Makefile.PL` 会改写受版本控制的文件
（`utilities/*.1`、`PerlMagick/quantum/quantum.pm`），所以切树用 `git checkout -f`。

## 5. 复现交付件本身

```bash
python tools/make_deliver.py                 # 重新生成 payload/（PoC、cases.tsv、vulnerabilities.*）
docker build -f deliver/image/Dockerfile -t im-arvo:2018-01-16 deliver
docker run -dit --name imarvo --security-opt seccomp=unconfined im-arvo:2018-01-16
docker exec -it imarvo imdt verify-before --no-build --report /tmp/rep/before
docker exec -it imarvo imdt verify-after  --no-build --report /tmp/rep/after
docker cp imarvo:/tmp/rep/before deliver/reports/before
docker cp imarvo:/tmp/rep/after  deliver/reports/after
```

`image/Dockerfile` 自己编译 6 个复现器，**不需要任何预编译产物**（旧版的
`COPY prebuilt/ /out/` 已删除，`prebuilt/` 目录也不再随包分发）。
