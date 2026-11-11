# verify — tree `fixed`

| field | value |
| --- | --- |
| tree | `fixed` = `8239e79ee4c8cc34034838eefe4f34bab02c5fc7` |
| other tree | `vuln` = `13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a` (different commit) |
| entry | `hand` → `$OUTROOT/hand-<profile>-<tree>/repro <coder> <poc>` |
| sanitizers | address undefined memory |
| cases | 68 |
| generated | 2026-11-10T23:42:36Z |
| format column | image format recorded by ARVO (`payload/vulnerabilities.json`) |

| localId | coder | sanitizer | format | result | SUMMARY |
| --- | --- | --- | --- | --- | --- |
| 42518038 | G3 | undefined | G3 | CLEAN | - |
| 42518438 | CIN | address | CIN | CLEAN | - |
| 42518471 | MIFF | memory | MIFF | CLEAN | - |
| 42518560 | TXT | memory | TXT | CLEAN | - |
| 42518649 | PALM | memory | PALM | CLEAN | - |
| 42518894 | WPG | memory | WPG | CLEAN | - |
| 42519182 | SUN | address | SUN | CLEAN | - |
| 42519338 | WPG | memory | WPG | CLEAN | - |
| 42519416 | SIXEL | address | SIXEL | CLEAN | - |
| 42519504 | EPSI | address | EPSI | CLEAN | - |
| 42519749 | SIX | address | SIX | CLEAN | - |
| 42519760 | PES | address | PES | CLEAN | - |
| 42519771 | TIM | memory | TIM | CLEAN | - |
| 42519915 | MIFF | memory | MIFF | CLEAN | - |
| 42520316 | EPS | address | EPS | CLEAN | - |
| 42520493 | DXT5 | address | DXT5 | CLEAN | - |
| 42520871 | EPS | memory | EPS | CLEAN | - |
| 42520948 | DCM | memory | DCM | CLEAN | - |
| 42520971 | PDB | memory | PDB | CLEAN | - |
| 42521159 | TXT | memory | TXT | CLEAN | - |
| 42521170 | WPG | memory | WPG | CLEAN | - |
| 42521270 | PCX | memory | PCX | CLEAN | - |
| 42521591 | MVG | address | MVG | CLEAN | - |
| 42521846 | PICT | memory | PICT | CLEAN | - |
| 42521858 | PALM | memory | PALM | CLEAN | - |
| 42521880 | VIFF | memory | VIFF | CLEAN | - |
| 42522269 | WBMP | memory | WBMP | CLEAN | - |
| 42522303 | WPG | memory | WPG | CLEAN | - |
| 42522513 | MVG | memory | MVG | CLEAN | - |
| 42522869 | PALM | memory | PALM | CLEAN | - |
| 42523358 | PNM | memory | PNM | CLEAN | - |
| 42523502 | VIFF | memory | VIFF | CLEAN | - |
| 42523812 | DPX | memory | DPX | CLEAN | - |
| 42523868 | MAT | memory | MAT | CLEAN | - |
| 42523879 | PSD | address | PSD | CLEAN | - |
| 42524289 | MVG | address | MVG | CLEAN | - |
| 42524701 | XCF | memory | XCF | CLEAN | - |
| 42525613 | PSD | memory | PSD | CLEAN | - |
| 42525647 | MIFF | memory | MIFF | CLEAN | - |
| 42525669 | MIFF | memory | MIFF | CLEAN | - |
| 42525880 | HDR | address | HDR | CLEAN | - |
| 42526335 | GIF | memory | GIF | CLEAN | - |
| 42526424 | EPSI | address | EPSI | CLEAN | - |
| 42526757 | PS | address | PS | CLEAN | - |
| 42527322 | PICT | memory | PICT | CLEAN | - |
| 42527699 | GIF | memory | GIF | CLEAN | - |
| 42527789 | MIFF | address | MIFF | CLEAN | - |
| 42528177 | MIFF | memory | MIFF | CLEAN | - |
| 42528200 | PCX | memory | PCX | CLEAN | - |
| 42528610 | SUN | memory | SUN | CLEAN | - |
| 42529799 | MIFF | memory | MIFF | CLEAN | - |
| 42530943 | MVG | address | MVG | CLEAN | - |
| 42530977 | HDR | memory | HDR | CLEAN | - |
| 42531054 | MIFF | memory | MIFF | CLEAN | - |
| 42531466 | DCM | address | DCM | CLEAN | - |
| 42532777 | SCR | memory | SCR | CLEAN | - |
| 42533154 | VIFF | memory | VIFF | CLEAN | - |
| 42533821 | MIFF | memory | MIFF | CLEAN | - |
| 42533954 | PCDS | memory | PCDS | CLEAN | - |
| 42533966 | MAC | memory | MAC | CLEAN | - |
| 42534188 | WPG | memory | WPG | CLEAN | - |
| 42534522 | TIM | memory | TIM | CLEAN | - |
| 42534621 | PDB | memory | PDB | CLEAN | - |
| 42534921 | MVG | address | MVG | CLEAN | - |
| 42535088 | MVG | address | MVG | CLEAN | - |
| 42535232 | RLE | memory | RLE | CLEAN | - |
| 42535688 | PDB | memory | PDB | CLEAN | - |
| 42537011 | MVG | address | MVG | CLEAN | - |

crash=0 clean=68

**verdict: PASS** — expected for `fixed`: crash=0 clean=68
