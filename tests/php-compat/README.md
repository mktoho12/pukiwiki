# PHP の版ごとの動作確認（PHP 4.1〜8.5）

2 つの版（git のリビジョン）の PukiWiki で同じページを表示し、出てくる HTML と警告の数を、PHP の版ごとに比べるための道具です。
BugTrack/2618（PHP 8.2〜8.5 の警告をなくす修正を、PHP4 で動くまま入れる）の確認に使いました。

## 必要なもの

- Docker と git
- PHP 4 のイメージを初めて作るときはネットにつながっていること（Debian の古い版のパッケージ置き場 archive.debian.org と、PHP の古い版の置き場 museum.php.net から取ってきます）

## 使い方

```sh
# 1.5.4（2cf98c4）と、いま見ている版を、PHP 4.1.2〜8.5 で比べる
tests/php-compat/run.sh 2cf98c4 HEAD

# 版を選ぶ（412 = PHP 4.1.2、85 = PHP 8.5 など）
tests/php-compat/run.sh 2cf98c4 HEAD 412 449 85
```

結果は 1 版 1 行で出ます。

```
PHP 412 (pukiwiki-php-compat:php412): NN pages, differing lines: 0, unfinished pages: 1 -> 1, errors: 59 -> 58
```

- `differing lines`: 2 つの版で HTML が違う行の数。0 なら表示は同じです
- `unfinished pages`: 出力が最後まで出なかったページの数（致命的なエラーや異常終了）。左が 1 つ目の版、右が 2 つ目の版です
- 違う行があるか、2 つ目の版のほうが `unfinished pages` が多いと、終了コードが 1 になります
- `errors`: 警告などの数（E_ALL）。左が 1 つ目の版、右が 2 つ目の版です
- 出力は `tests/php-compat/out/` に残ります（版ごとの HTML と `errors.log`）。中身を比べるには `diff -r tests/php-compat/out/85-base tests/php-compat/out/85-target` など

## PHP の版

| 指定 | PHP | 中身 |
|---|---|---|
| 412 | 4.1.2 | Debian 3.0（woody）のパッケージ（`docker/php412.Dockerfile`） |
| 444 | 4.4.4 | Debian 4.0（etch）のパッケージ（`docker/php444.Dockerfile`） |
| 449 | 4.4.9 | etch の上でソースから組み立てる（`docker/php449.Dockerfile`。数分かかります） |
| 56〜85 | 5.6〜8.5 | 公式の `php:X.Y-cli` イメージ（php-cgi が入っています） |

PHP 4 のイメージは、初めて使うときに作られ、`pukiwiki-php-compat:php412` などの名前で残ります。

## 表示するもの

- `wiki/` の標準のページと、`pages/` の試験用のページ（下記）
- 一覧・検索・RSS・編集・差分・バックアップ・関連・ソースの各画面

`render.sh` が、PukiWiki を複製して `index.php` の `error_reporting()` を E_ALL にし、php-cgi で 1 ページずつ表示します。ファイルの時刻はすべて 2020-01-01 にそろえ、実行のたびに変わる部分（処理時間、`data-mtime`）は消してから比べます。

## 試験用のページ（`pages/`）

すべて架空の内容です（ファイル名は PukiWiki の形式で、ページ名を 16 進にしたもの）。

| ページ | 内容 |
|---|---|
| ConvertTest、ConvertTest2 | 書式の組み合わせ（入れ子のリスト、引用の閉じ方、表、整形済みテキストなど）を詰め込んだもの |
| 試験町 | 架空の町の紹介。行内の書式、リンク、注釈、リスト、引用、表など |
| 試験町/図書館 | 表（見出し・フッタ・書式指定の行、結合）、定義リスト、整形済みテキスト |
| 試験町/商店街 | リストと引用と表の切り替わり、#include |
| 試験町/お知らせ | #include される側 |
| 試験町/商店街/パン屋 | #topicpath |
| 試験町/掲示板 | プラグイン（#comment、#vote、#ls2、#recent、#calendar2 など）と行内プラグイン |
| 試験町/年表 | 機械的に作った約 1,900 行の大きなページ |
| 試験町/カウンター | #counter と #popular。counter プラグインは 1.5.4 の時点で PHP 4 では構文エラーになるので（`unfinished pages` の 1）、このページだけに置いています |

## その他

- `copy-demo.php`: PHP 4 で、どんなときにオブジェクトがコピーされるかを示すもの。`$obj = new A()` ではコピーされ、`function &` の中の `return new A();` ではコピーされません（後者は PHP 5 以降で Notice になります）
- woody の道具は古いので（`sed -i` や `find -exec ... +` が無い）、`render.sh` はそれに合わせて書いています
