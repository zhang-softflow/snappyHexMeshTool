# foamSHM — snappyHexMeshDict のキーワード辞典・雛形生成・検査ツール

[English](README.md) | 日本語

snappyHexMeshDict には、geometry / castellatedMeshControls / snapControls / addLayersControls / meshQualityControls と、その入れ子に約190のキーワードがあります。使うたびに「どこに置くか」「必須か」「既定値は何か」「どんな値を選べるか」を annotated 辞書、ソース、tutorials から探すのは手間がかかります。

**foamSHM** は次の情報を解析して、snappyHexMeshDict の**キーワード辞典**を作ります。そのデータベースを使って、検索、表示、雛形の作成、既存の辞書の検査ができます。

- annotated 辞書（`etc/caseDicts/annotated/snappyHexMeshDict`。コメントアウトされた任意項目も戻して解析します）と `etc/caseDicts/meshQualityDict`
- 辞書を読み込む C++ のソース（`get` / `getOrDefault` / `readIfPresent` / `found` …）。ここから必須・任意と既定値を取ります
- Enum の名前表（`mode`、`cellZoneInside`、`faceType`、`thicknessModel` などで選べる値）
- geometry の型（searchableSurface。box、cylinder、triSurfaceMesh …）のヘッダのパラメータ表
- tutorials のすべての snappyHexMeshDict（実際の使用例）

キーワードは、ユーザーが付ける名前をプレースホルダにしたパスで表します（例 `castellatedMeshControls/refinementSurfaces/<surface>/level`）。

functionObject 用の [foamFO](../functionObjects)、fvOptions 用の [foamFV](../fvOptions) と同じ使い方です。

| ファイル | 内容 |
|---|---|
| `foamSHM` | CLI（Python 3.8 以上、標準ライブラリのみ） |
| `catalog.html` | 検索できるリファレンス。ブラウザで開くだけで使えます（オフライン、単一ファイル） |
| `shmDatabase.json` | 同梱のデータベース（OpenFOAM-v2606 から生成） |
| `catalog_template.html` | カタログの雛形 |
| `skill/openfoam-snappyhexmesh/` | Claude Code 用スキル |
| `install.sh` | インストール補助（スキルのリンク、PATH の設定） |

## インストール

```bash
cd snappyHexMesh        # このディレクトリ
./install.sh            # ~/.claude/skills にスキルをリンクし、PATH 設定の1行を表示
./install.sh --bashrc   # ~/.bashrc に PATH を追記する場合（バックアップあり）
./install.sh --uninstall
```

使う OpenFOAM が v2606 以外の場合は、その環境を読み込んでからデータベースを作ってください（1秒程度で終わります）。

```bash
source /usr/lib/openfoam/openfoam2412/etc/bashrc
foamSHM build           # -> ~/.local/share/foamSHM/shmDatabase-openfoam2412.json
```

- **探索順**: `$FOAMSHM_DB` → `~/.local/share/foamSHM/shmDatabase-<版>.json` → 同梱の `shmDatabase.json`
- **版が違う場合**: 同梱のデータベースの版と環境の版が違うと警告が出ます（`FOAMSHM_QUIET=1` で抑止できます）。

## 使い方

| コマンド | 説明 |
|---|---|
| `foamSHM tree [addLayersControls] [-d] [-a]` | 辞書の構造を表示します（R=必須、C=条件付き、o=任意、既定値、選択肢。`-d` で説明も表示） |
| `foamSHM search 境界層 厚さ` | キーワード、説明、同義語を全文検索します（`gap`、`隙間`、`ゾーン`、`特徴線` なども可） |
| `foamSHM show nCellsBetweenLevels` | 置く場所、必須/任意、既定値、選択肢、条件、annotated の説明と例、読み込むソースの位置、tutorials での値を表示します |
| `foamSHM show level` | 同じ名前が複数の場所にある場合は、すべて表示します |
| `foamSHM show refinementSurfaces/motorBike/level` | 実名を含むパスでも引けます |
| `foamSHM show cylinder` | geometry の型のパラメータ表、ヘッダの例、tutorials での使用回数を表示します |
| `foamSHM example refinementRegions -m 2` | tutorials 内の実際の記述を抜き出して表示します（OpenFOAM 環境または `--src` が必要） |
| `foamSHM template -case . --layers 3 --features --shape box:refineBox` | 雛形を表示します（書き込みはしません） |
| `foamSHM template ... --write` | `system/snappyHexMeshDict` に書きます（既存のファイルは `.bak` に退避） |
| `foamSHM check [case]` | 既存の辞書を検査します（`--dict-only` でケースのファイルを見ない、`-q` で INFO を隠す） |
| `foamSHM build [--src DIR] [-o FILE] [-v]` | データベースを作ります（`-v` で、ソースと annotated の食い違いを一覧表示） |
| `foamSHM html` | `catalog.html` を作り直します |

### template
- `--stl` を省略すると、`constant/triSurface`（または `constant/geometry`）の面をすべて使います。`.gz` は外した名前で参照します。
- `--shape <型>:<名前>`（box、cylinder、sphere など）で細分化領域を加えます。`<xmin>` などのプレースホルダが残ります。
- `--level MIN MAX`、`--layers N`、`--features`（`<面>.eMesh` による特徴線の細分化とスナップ）、`--zone <面>`（faceZone/cellZone）、`--location "(x y z)"`、`--include-quality`（`#include "meshQualityDict"` を使う）
- blockMesh の範囲が分かる場合は、locationInMesh の横にコメントで示します。
- 生成した辞書は、自分のデータベースで検査してから出力します（未知のキーワードがあれば警告）。

### check
| レベル | 内容 |
|---|---|
| ERROR | 必須項目の欠落（`addLayers false` のときの addLayersControls の中身など、読まれない場合は対象外）、選択肢以外の値、geometry の型の必須パラメータの欠落、blockMesh の範囲外の locationInMesh |
| WARN | 未知のキーワード（`did you mean` で近い名前を提示）、geometry に無い名前（snappyHexMesh は「Not all entries ... were used」と警告して無視します）、見つからない STL / eMesh、addLayers true なのに空の layers |
| INFO | tutorials にしか無い（ソースで読み込みが見つからない）キーワード、解決できない `#include` |

- `#include`、`#includeEtc`（`<system>` などの表記を含む）を展開し、同じキーの辞書はマージしてから検査します。`$変数` を含む辞書では「必須項目の欠落」は報告しません。
- 文法の最終確認には `foamDictionary system/snappyHexMeshDict -expand` と `snappyHexMesh -dry-run` を併用してください。

## catalog.html

ブラウザで開くだけで使えます。OpenFOAM がインストールされていなくても見られます。

- **左側**: セクションのツリー（R/C/o と既定値）、インクリメンタル検索（`/` キー、日本語の同義語を含む）、「必須のみ」「tutorials で使用」「説明を表示」の絞り込み、geometry の型の一覧、テンプレート
- **右側**: 置く場所を示した記述例（入れ子の辞書ごと Copy できます）、既定値、選択肢、条件、annotated の説明と例、子の項目の一覧、tutorials での値、読み込むソースの位置
- **項目を直接開く**: `catalog.html#nSurfaceLayers`、`catalog.html#addLayersControls/featureAngle`、`catalog.html#box` のように末尾に名前を付けます

## Claude Code スキル

`install.sh` で `~/.claude/skills/openfoam-snappyhexmesh` にリンクされます。
「この STL の周りにメッシュを作って境界層を3層入れたい」「境界層が入らない」のように頼むと、foamSHM でキーワード・既定値・置く場所を確認し、ケース（STL、blockMesh の範囲、パッチ名）を確かめてから辞書を書き、`foamSHM check` で検査します。名前で呼ぶ場合は `/openfoam-snappyhexmesh` です。

## OpenFOAM の既存機能
```bash
cat $WM_PROJECT_DIR/etc/caseDicts/annotated/snappyHexMeshDict   # annotated dictionary
foamGetDict snappyHexMeshDict                                     # copy it into system/
foamDictionary system/snappyHexMeshDict -expand                   # syntax check (resolves #include)
snappyHexMesh -dry-run                                            # set-up check without meshing
surfaceCheck constant/triSurface/<file>                           # closedness/quality of a surface
```
- `#includeEtc "caseDicts/mesh/generation/snappyHexMeshDict.cfg"` で共通の既定値を読み込み、ケース側では差分だけを書く方法もあります（foamSHM の `show` に「etc cfg」の値として表示されます）。

## 制限と注意
- 対応しているのは **ESI 版（openfoam.com, vYYMM）** です。Foundation 版（openfoam.org）には対応していません。
- 必須/任意はソースの読み方から自動で判定しています。条件によって読まれ方が変わる項目（厚さの指定、`locationInMesh` / `locationsInMesh`、`insidePoint` など）は、ツール内の対応表で「条件付き」と説明を補っています。
- geometry の型ごとのパラメータの検査は、ヘッダのパラメータ表と tutorials での使用例に基づきます。表に載っていないパラメータは INFO（近い名前がある場合は WARN）になります。
- `*Coeffs`、`patchInfo`、`formatOptions` の中身は他のクラスに渡されるため、検査しません。
- 動作確認の範囲:
  - DB の生成: v2606（ソース）と v2412（パッケージ版）
  - 検査: v2606 の tutorials の 67 個の snappyHexMeshDict すべてで誤検出（ERROR）なし
  - 雛形の実行: v2412 で motorBike の形状に `template --level 4 5 --layers 3 --shape box:refinementBox` を適用し、snappyHexMesh が完走（186,019セル、境界層の押し出し 17%、checkMesh で skewness の大きい面が7面）。レベルと層の設定は形状に合わせて調整してください

## ライセンス
GPL-3.0-or-later（[LICENSE](LICENSE)）。
同梱の `shmDatabase.json` と `catalog.html` には、OpenFOAM のソースと annotated 辞書（GPL-3.0-or-later、© OpenCFD Ltd. ほか）のコメントの文章が含まれます。

OPENFOAM® is a registered trade mark of OpenCFD Limited, producer and distributor of the OpenFOAM software via www.openfoam.com. This offering is not approved or endorsed by OpenCFD Limited.
