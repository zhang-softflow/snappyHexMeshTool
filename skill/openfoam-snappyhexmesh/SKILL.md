---
name: openfoam-snappyhexmesh
description: Write, explain or check OpenFOAM (ESI/openfoam.com) snappyHexMeshDict settings — e.g. "mesh around this STL with 3 boundary layers", "refine inside a box", "how do I set the first layer thickness", "make a cellZone from this surface", "why are no layers added", "check my snappyHexMeshDict". OpenFOAM（ESI版）の snappyHexMeshDict の設定を書く・説明する・確認するときに使う。「この STL の周りにメッシュを作って境界層を3層入れたい」「箱の中だけ細かくしたい」「第1層の厚さを指定したい」「この面から cellZone を作りたい」「境界層が入らない」「snappyHexMeshDict をチェックして」のように、目的を自然文で受け取り、ソース・annotated 辞書・tutorials に基づいて正しい記述を作る。
---

# OpenFOAM snappyHexMesh 設定支援

`foamSHM` は、snappyHexMeshDict のキーワードのデータベースを検索・表示し、雛形の作成と辞書の検査を行うツールです。データベースは次の情報から作られています。
- annotated 辞書（`etc/caseDicts/annotated/snappyHexMeshDict`、コメントアウトされた任意項目を含む）と `etc/caseDicts/meshQualityDict`
- 辞書を読む C++ のソース（必須・任意、既定値）と Enum の名前表（選べる値）
- geometry の型（searchableSurface）のヘッダ
- tutorials のすべての snappyHexMeshDict（実際の使用例）

このスキルでは、**キーワード名・置く場所・値の選択肢を、すべて foamSHM が返す内容に基づいて書く**ことを原則とします。記憶や推測でキーワードを書かないでください（例: `nCellsBetweenLevels`（"Cell" ではなく "Cells"）、`relativeSizes`、`locationInMesh`、`refinementRegions` の `levels ((距離 レベル))` などは間違えやすい項目です）。

ツールの場所:
- `foamSHM` が PATH にあればそれを使います（`command -v foamSHM` で確認）。
- PATH に無い場合は、このスキルのベースディレクトリから見て `../../foamSHM` を使います（リポジトリ同梱）。

データベース:
- 同梱の DB は OpenFOAM-v2606 から作ったものです。
- ユーザーの OpenFOAM の版が違い、「bundled database is for ...」という警告が出た場合は、OpenFOAM 環境を source した状態で `foamSHM build` を実行します（数秒）。作られた DB はその版で自動的に使われます。
- `example` コマンドで tutorials の記述を表示するには、OpenFOAM 環境（`$WM_PROJECT_DIR`）が必要です。環境が無い場合は `--src <OpenFOAMのルート>` を指定します。

回答はユーザーの言語で行います。

## 手順

1. **目的をキーワードに対応付ける**
   - `foamSHM search <語...>` で探します（英語でも日本語でも可。例: `layer thickness`、`境界層`、`隙間`、`ゾーン`、`特徴線`）。
   - 全体像は `foamSHM tree [セクション] [-d]` で確認します（R=必須、C=条件付き、o=任意。既定値と選択肢も表示されます）。
   - よく使う対応:
     - 表面の細分化 → `castellatedMeshControls/refinementSurfaces/<surface>/level (min max)`
     - 領域（箱・円柱など）の細分化 → geometry に `type box` などを定義し、`refinementRegions/<name>` で `mode inside; levels ((1e15 <level>));`
     - 表面からの距離による細分化 → `mode distance; levels ((<距離1> <level1>) (<距離2> <level2>));`
     - 特徴線（エッジ）の解像 → `surfaceFeatureExtract` で `.eMesh` を作り、`features ( { file "<name>.eMesh"; level <n>; } )` と `snapControls/explicitFeatureSnap true`
     - 境界層 → `addLayers true;` と `addLayersControls/layers/<patch>/nSurfaceLayers`、厚さは `thicknessModel` または2つの厚さ指定
     - cellZone / faceZone（MRF・多孔質・バッフル） → `refinementSurfaces/<surface>` に `faceZone`、`cellZone`、`cellZoneInside`、必要なら `faceType baffle`
     - マルチリージョン → `locationsInMesh ((<点> <zone>) ...)`
     - 狭い隙間の解像 → `gapLevel (<セル数> <min> <max>)`、`gapMode`
   - この対応は手がかりにすぎません。必ず次の手順で裏付けを取ってください。

2. **正しい記述を確認する**
   - `foamSHM show <キーワードまたはパス>` で、置く場所（パス）、必須/任意、既定値、選択肢、条件（「addLayers true のときだけ読まれる」など）、annotated の説明と例、読み込んでいるソースの位置、tutorials での値を確認します。
     - 同じ名前が複数の場所にある場合（`level`、`expansionRatio`、`concaveAngle` など）はすべて表示されます。置く場所を取り違えないでください。
     - 実名を含むパス（`refinementSurfaces/motorBike/level`）でも引けます。
   - geometry の型は `foamSHM show box`（cylinder、sphere、triSurfaceMesh、rotatedBox、plate、disk、cone など）でパラメータ表を確認します。
   - 実際の使い方は `foamSHM example <キーワードまたは型> -m 3` で tutorials から確認します。
   - 情報が足りない場合は、`show` の「Read in:」に表示されるソースのファイルと行を直接 Read して確認します。

3. **ケースを確認する**
   - **形状ファイル**: `constant/triSurface/`（または `constant/geometry/`）にある STL/OBJ などの名前を確認します。`.gz` は付けずに参照します（`motorBike.obj` → ファイルは `motorBike.obj.gz` でも可）。
   - **名前の対応**: `refinementSurfaces` などのキーは geometry の名前（`name` があればそれ、無ければエントリ名）でなければなりません。パッチ名は、単一領域の面なら面の名前、複数領域なら `<面>_<領域>` になります。`layers` のキーはこのパッチ名（正規表現も可。例 `"motorBike.*"`）です。geometry の名前は使えません。
   - **背景メッシュ**: `system/blockMeshDict` の範囲を確認し、`locationInMesh` が範囲内かつ残したい側（流体側）にあり、セルの面上に乗らない位置（例 `3.0001` のような端数）であることを確認します。
   - **特徴線**: `features` を使う場合は `system/surfaceFeatureExtractDict` と `surfaceFeatureExtract` の実行が必要です。
   - **meshQualityControls**: `#include "meshQualityDict"` を使う場合は `system/meshQualityDict` が必要です（無ければ `cp $WM_PROJECT_DIR/etc/caseDicts/meshQualityDict system/` か、値を直接書きます）。

4. **設定を作る**
   - 新規作成は `foamSHM template -case <case> [--stl <file>] [--shape box:<name>] [--level MIN MAX] [--layers N] [--features] [--zone <surface>] [--location "(x y z)"]` で雛形を表示します（`--write` を付けない限り表示だけです）。
     - `--stl` を省略すると `constant/triSurface` の面をすべて使います。
     - `<xmin>` などの `<…>` はプレースホルダです。ユーザーの条件で置き換えてください。
   - 既存の辞書に追記する場合は、`show` で確認した場所に Edit で書き足します。
   - 値の意味（相対/絶対の厚さ、レベルとセル寸法の関係: レベル n のセルは背景セルの 1/2^n）を説明に明記します。

5. **検査する**
   - `foamSHM check <case>` で検査します。
     - ERROR: 必須項目の欠落、選択肢以外の値、型の必須パラメータの欠落、範囲外の locationInMesh
     - WARN: 未知のキーワード（近い名前を提示）、geometry に無い名前、見つからない STL/eMesh、空の layers
     - INFO: tutorials にしか無い（ソースで読まれていない）キーワードなど
     - ケースのファイルがまだ揃っていない場合は `--dict-only` を付けます。
   - OpenFOAM 環境がある場合は、さらに `foamDictionary system/snappyHexMeshDict -expand` と `snappyHexMesh -dry-run` で確認するよう伝えます。
   - ユーザーが書き込みを求めた場合のみ `--write`（既存ファイルは `.bak` にバックアップ）またはファイルの編集を行います。

## よくある相談への確認項目
- **境界層が入らない・薄い**: `layers` のキーがパッチ名と一致しているか、`relativeSizes` と厚さの組み合わせ、`featureAngle`（大きいほど角でも押し出す）、`nGrow`、`maxFaceThicknessRatio`、`minThickness`、`meshQualityControls`（特に `minTetQuality`、`maxNonOrtho`、`relaxed`）、ログの `Extruding N out of M faces` を確認します。
- **形状の内側にメッシュが残る/消える**: `locationInMesh` の位置、面の閉じ具合（`surfaceCheck`）、`maxGlobalCells` に達して細分化が途中で止まっていないかを確認します。
- **エッジがつぶれる**: `features` と `explicitFeatureSnap`、`resolveFeatureAngle`、`nFeatureSnapIter` を確認します。
- **並列実行**: `decomposePar` の後に `mpirun -np N snappyHexMesh -parallel -overwrite`、その後 `reconstructParMesh -constant` です。
- **各段階の切り替え**: `castellatedMesh`、`snap`、`addLayers` を true/false で切り替え、段階ごとに確認できます（`-overwrite` を付けない場合は時刻フォルダに段階ごとのメッシュが書かれます）。

## 出力のしかた
- ユーザーの言語で説明し、最終的な snappyHexMeshDict の該当部分（またはファイル全体）を示します。
- 主要な項目の意味と、変更した項目の既定値を、`show` の内容に基づいて添えます。
- 実行の手順（`blockMesh` → `surfaceFeatureExtract` → `snappyHexMesh -overwrite` → `checkMesh`）と、`foamSHM check` での確認を一言添えます。
