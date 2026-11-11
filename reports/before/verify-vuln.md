# verify — tree `vuln`

| field | value |
| --- | --- |
| tree | `vuln` = `13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a` |
| other tree | `fixed` = `8239e79ee4c8cc34034838eefe4f34bab02c5fc7` (different commit) |
| entry | `hand` → `$OUTROOT/hand-<profile>-<tree>/repro <coder> <poc>` |
| sanitizers | address undefined memory |
| cases | 68 |
| generated | 2026-11-10T23:42:25Z |
| format column | image format recorded by ARVO (`payload/vulnerabilities.json`) |

| localId | coder | sanitizer | format | result | SUMMARY |
| --- | --- | --- | --- | --- | --- |
| 42518038 | G3 | undefined | G3 | CRASH | SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior MagickCore/compress.c:835:28 in  |
| 42518438 | CIN | address | CIN | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/./MagickCore/quantum-private.h in PushLongPixel |
| 42518471 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/property.c:1750:3 in GetXMPProperty |
| 42518560 | TXT | memory | TXT | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/cache.c:3954:61 in QueueAuthenticPixelCacheNexus |
| 42518649 | PALM | memory | PALM | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/pixel.c:6132:7 in IsFuzzyEquivalencePixelInfo |
| 42518894 | WPG | memory | WPG | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/cache.c:3368:11 in WritePixelCacheRegion |
| 42519182 | SUN | address | SUN | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/MagickCore/quantize.c:3411:55 in SetGrayscaleImage |
| 42519338 | WPG | memory | WPG | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/colormap-private.h:32:7 in ConstrainColormapIndex |
| 42519416 | SIXEL | address | SIXEL | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/llvm/projects/compiler-rt/lib/asan/asan_interceptors_memintrinsics.cc:27 in __asan_memset |
| 42519504 | EPSI | address | EPSI | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/MagickCore/xml-tree.c:1525:19 in ParseEntities |
| 42519749 | SIX | address | SIX | CRASH | SUMMARY: AddressSanitizer: SEGV /src/imagemagick/coders/sixel.c:462:73 in sixel_decode |
| 42519760 | PES | address | PES | CRASH | SUMMARY: AddressSanitizer: stack-buffer-overflow /src/imagemagick/coders/pes.c:624:19 in ReadPESImage |
| 42519771 | TIM | memory | TIM | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/image.c:3700:7 in PushColormapIndex |
| 42519915 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/locale.c:1518:10 in LocaleNCompare |
| 42520316 | EPS | address | EPS | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/llvm/projects/compiler-rt/lib/asan/../sanitizer_common/sanitizer_common_interceptors.inc:707 in strspn |
| 42520493 | DXT5 | address | DXT5 | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/./MagickCore/pixel-accessor.h:844:52 in SetPixelRed |
| 42520871 | EPS | memory | EPS | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/xml-tree.c:1506:28 in ParseEntities |
| 42520948 | DCM | memory | DCM | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:522:55 in IsPixelGray |
| 42520971 | PDB | memory | PDB | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/pdb.c:349:45 in ReadPDBImage |
| 42521159 | TXT | memory | TXT | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum.h:116:7 in ScaleQuantumToChar |
| 42521170 | WPG | memory | WPG | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:783:32 in SetPixelViaPixelInfo |
| 42521270 | PCX | memory | PCX | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:567:50 in IsPixelMonochrome |
| 42521591 | MVG | address | MVG | CRASH | SUMMARY: AddressSanitizer: stack-buffer-overflow /src/imagemagick/MagickCore/token.c:313:24 in GetNextToken |
| 42521846 | PICT | memory | PICT | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/colormap-private.h:32:7 in ConstrainColormapIndex |
| 42521858 | PALM | memory | PALM | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/pixel.c:6132:7 in IsFuzzyEquivalencePixelInfo |
| 42521880 | VIFF | memory | VIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum.h:116:7 in ScaleQuantumToChar |
| 42522269 | WBMP | memory | WBMP | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/wbmp.c:164:7 in ReadWBMPImage |
| 42522303 | WPG | memory | WPG | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:783:32 in SetPixelViaPixelInfo |
| 42522513 | MVG | memory | MVG | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/draw.c:3948:9 in GetFillAlpha |
| 42522869 | PALM | memory | PALM | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum.h:116:7 in ScaleQuantumToChar |
| 42523358 | PNM | memory | PNM | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:487:7 in IsPixelEquivalent |
| 42523502 | VIFF | memory | VIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/image.c:3700:7 in PushColormapIndex |
| 42523812 | DPX | memory | DPX | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum-private.h:504:7 in ScaleQuantumToShort |
| 42523868 | MAT | memory | MAT | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:522:55 in IsPixelGray |
| 42523879 | PSD | address | PSD | CRASH | SUMMARY: AddressSanitizer: negative-size-param /src/llvm/projects/compiler-rt/lib/asan/asan_interceptors_memintrinsics.cc:23 in __asan_memcpy |
| 42524289 | MVG | address | MVG | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/MagickCore/draw.c:1666:30 in TracePoint |
| 42524701 | XCF | memory | XCF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:37:7 in ClampPixel |
| 42525613 | PSD | memory | PSD | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum-private.h:504:7 in ScaleQuantumToShort |
| 42525647 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/property.c:1336:9 in GetEXIFProperty |
| 42525669 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/locale.c:1518:10 in LocaleNCompare |
| 42525880 | HDR | address | HDR | CRASH | SUMMARY: AddressSanitizer: stack-buffer-overflow /src/llvm/projects/compiler-rt/lib/asan/asan_interceptors_memintrinsics.cc:23 in __asan_memcpy |
| 42526335 | GIF | memory | GIF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/profile.c:1859:9 in Sync8BimProfile |
| 42526424 | EPSI | address | EPSI | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/llvm/projects/compiler-rt/lib/asan/../sanitizer_common/sanitizer_common_interceptors.inc:707 in strspn |
| 42526757 | PS | address | PS | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/MagickCore/xml-tree.c:2288:35 in NewXMLTree |
| 42527322 | PICT | memory | PICT | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum.h:116:7 in ScaleQuantumToChar |
| 42527699 | GIF | memory | GIF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/profile.c:1844:9 in Sync8BimProfile |
| 42527789 | MIFF | address | MIFF | CRASH | SUMMARY: AddressSanitizer: stack-buffer-overflow /src/imagemagick/MagickCore/color.c:2385:23 in QueryColorCompliance |
| 42528177 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/color.c:2385:11 in QueryColorCompliance |
| 42528200 | PCX | memory | PCX | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum.h:116:7 in ScaleQuantumToChar |
| 42528610 | SUN | memory | SUN | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum.h:116:7 in ScaleQuantumToChar |
| 42529799 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/miff.c:2147:36 in WriteMIFFImage |
| 42530943 | MVG | address | MVG | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/MagickCore/draw.c:1666:30 in TracePoint |
| 42530977 | HDR | memory | HDR | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/hdr.c:485:11 in ReadHDRImage |
| 42531054 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/miff.c:2240:9 in WriteMIFFImage |
| 42531466 | DCM | address | DCM | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/imagemagick/coders/dcm.c:3964:27 in ReadDCMImage |
| 42532777 | SCR | memory | SCR | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/scr.c:232:19 in ReadSCRImage |
| 42533154 | VIFF | memory | VIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/viff.c:571:15 in ReadVIFFImage |
| 42533821 | MIFF | memory | MIFF | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/quantum.h:116:7 in ScaleQuantumToChar |
| 42533954 | PCDS | memory | PCDS | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/pixel-accessor.h:37:7 in ClampPixel |
| 42533966 | MAC | memory | MAC | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/image.c:3700:7 in PushColormapIndex |
| 42534188 | WPG | memory | WPG | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/./MagickCore/colormap-private.h:32:7 in ConstrainColormapIndex |
| 42534522 | TIM | memory | TIM | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/image.c:3700:7 in PushColormapIndex |
| 42534621 | PDB | memory | PDB | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/image.c:3700:7 in PushColormapIndex |
| 42534921 | MVG | address | MVG | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/llvm/projects/compiler-rt/lib/asan/asan_interceptors_memintrinsics.cc:23 in __asan_memcpy |
| 42535088 | MVG | address | MVG | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/llvm/projects/compiler-rt/lib/asan/asan_interceptors_memintrinsics.cc:23 in __asan_memcpy |
| 42535232 | RLE | memory | RLE | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/MagickCore/string.c:697:13 in ConstantString |
| 42535688 | PDB | memory | PDB | CRASH | SUMMARY: MemorySanitizer: use-of-uninitialized-value /src/imagemagick/coders/pdb.c:886:15 in WritePDBImage |
| 42537011 | MVG | address | MVG | CRASH | SUMMARY: AddressSanitizer: heap-buffer-overflow /src/llvm/projects/compiler-rt/lib/asan/asan_interceptors_memintrinsics.cc:23 in __asan_memcpy |

crash=68 clean=0

**verdict: PASS** — expected for `vuln`: crash=68 clean=0
