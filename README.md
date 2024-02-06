# Clipkitテーマ開発環境

Clipkitのテーマをオフラインで開発できる環境です。管理画面を使わずローカルのテキストエディタでテンプレートを書くことができ、バンドルツールに対応しており制約なく最新のjsライブラリやツールを使うことができます。

## 必要なもの

- [AWS CLI](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)
- [Docker](https://www.docker.com/ja-jp/products/docker-desktop/)

## Dockerイメージ取得（初回のみ）

アクセスキーとシークレットは別途お伝えします。

```shell
$ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
$ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
$ aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 740658765198.dkr.ecr.ap-northeast-1.amazonaws.com
```

## 開発環境を起動

```shell
$ docker compose up
```

htto://localhost:3000/ でアクセスできます。

## ディレクトリ構成

- src/
  - theme_1/
    - templates/
    - files/
    - theme.yml

テーマのソースです。ここを編集してください。

- dest/
  - theme_1/
    - templates/
    - files/
    - theme.yml

ESBuildでビルドされたファイルです。src/を更新するとリアルタイムにビルドされます。
これをzip圧縮するとテーマファイルになります。

- node
  - esbuild.js
  - package.json

ESBuildの設定、package.jsonは自由に変更してください。
