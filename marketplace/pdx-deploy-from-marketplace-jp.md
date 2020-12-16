# Deploy Oracle Property Graph Server from Marketplace

前の記事([Oracle Property Graph serverのセットアップとその活用方法をまとめてみた](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart/blob/master/manual-setup/pgx-manual-setup-dbcs.md))で、DBCSインスタンス上でOracle Graph Server and Clientをセットアップする方法を紹介しました。しかし、その手順は一つ一つ手作業でしたし、グラフサーバとデータベースインスタンスは同じサーバ(VM)の中に配置されています。これはベストプラクティスとは正直言えないアプローチです...。グラフサーバとデータベースインスタンスは、お互いに干渉を防ぐためにも、それぞれ異なるサーバにデプロイしておくべきです。

と言うか、デプロイにはもっと簡単な方法はあるんじゃないでしょうか。

だってクラウドですから。

## 事前準備

グラフサーバは、DBCSインスタンスより手前にインストールしていきたいです。
そのために、データベースのいくつかの設定を変更する必要があります。

詳しくは、[前記事のこちら](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart/blob/master/manual-setup/pgx-manual-setup-dbcs.md#configuration-in-oracle-database)を参照してください。

### Oracle Databaseの設定


`oracle`ユーザに変更後、`sys`ユーザとして、Oracle Databaseに接続していきましょう、

```sh
sudo su - oracle
sqlplus / as sysdba
```

[Figure: connect to DB]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f5cd3c63-eb09-839c-bb06-e667f50786fc.png)

- PL/SQLパッケージ

Oracle Graph Server and Clientは、Oracle Database 12.2かそれ以降に対応しています。
しかし、[Oracle Graph Server and Client download](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html)から最新版のPL/SQLパッケージをインストールする必要があります。

`Oracle Graph Client for PL/SQL` をダウンロードして、解凍したファイルは任意のディレクトリに保存して下さい。

Oracle Databaseにログインして、下記のスクリプトを実行しましょう

```sql
-- Connect as SYSDBA
SQL> alter session set container=<YOUR_PDB_NAME>;
SQL> @opgremov.sql
SQL> @catopg.sql
```

注記: 未解凍のZipディレクトリには2つのディレクトリがあると思います。一つは、Oracle Database 18c以下を使っているユーザのためのもの。もう一つが、Oracle Database 19c以降を使っているユーザ用です。DBA権限を持つデータベースユーザとして、REAME.mdファイル内のインストラクションに従って下さい。インストラクションを参考にする時は、自分のデータベースのバージョンに合っているか確認してください。これは、グラフ機能が入ったPDBを使用する際に、都度必要になります。私が作ったDBCSインスタンスは19cですから、私は19c_and_aboveのスクリプトを流していきます。

- ユーザとロール

PDBである`pdb1`に`demograph`ユーザを作成して、ロールや表領域を下記のようにグラントしましょう。
全ての表は、`demograph`スキーマで作成されロードされていくことになります。

```sql
CREATE USER demograph IDENTIFIED BY <PASSWORD>;
GRANT CONNECT, resource TO demograph;
GRANT ALTER SESSION,CREATE PROCEDURE,CREATE SESSION,CREATE TABLE, CREATE TYPE, CREATE VIEW to demograph;

CREATE ROLE graph_developer;
CREATE ROLE graph_administrator;

GRANT graph_developer TO demograph;
GRANT graph_administrator to demograph;

ALTER USER demograph QUOTA 10G ON USERS

GRANT UNLIMITED TABLESPACE TO demograph;
```

[Figure: prepare DB user `demograph`]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b7fe513d-e5cf-82e3-77d0-38b813b0bf1a.png)

### Online Retail表を作成する

[Create and populate the Online Retail tables](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart/blob/master/create-and-populate-online-retail-tables/create-and-populate-online-retail-tables.md) を参照して作成してください。



## Marketplaceからデプロイする


OCI Marketplaceの検索バーで`graph`と入力し、検索してください。
Oracle Property Graph Server & Client imageがヒットするはずです。

[Figure: Marketplace]
![marketplace.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/2c5c52eb-7115-a06f-b036-a95b7beb2631.png)

[Figure: PGX in marketplace]
![PGX in marketplace](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/bbb9ffc7-8ae0-cc11-71be-189759c4a359.png)

`Launch Stack` ボタンをクリックする前に、`Overview`と`Usage Instructions`は読んでおいて下さい。

[Figure: Launch Stack]
![Launch Stack](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/8f02d3e3-1754-82b0-4db7-6ed5e8541964.png)

任意にスタックの名称を入力後、コンパートメントは、スタックをlaunchした時と同じコンパートメントを選択して下さい。

[Figrue: Stack info 1]
![Stack info 1](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/622120a0-f16f-50c7-d09a-1cd976f5b859.png)

On the next page, we need to input more information.

次のページから、更に情報を入力していきます。

Oracle Graph Server コンピュートインスタンスのセクションでは、下記の情報を入力していきます。

- `RESOURCE NAME PREFIX`は、作成したリソースの特定に役立ちます。
- `ORACLE GRAPH SERVER COMPARTMENT`では、graph serverをデプロイするコンパートメントを選択することができます。
- `ORACLE GRAPH SERVER SHAPE`では、サーバのパフォーマンスを決める、シェイプの選択ができます。 シェイプについては、[VM Shape page](https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm#vmshapes)をご参照ください。
- `SSH PUBLIC KEY`には、グラフサーバがデプロイさせたコンピュートインスタンスにアクセスするための公開鍵を、預けましょう。
[Figure: Stack info 2-1]
![Stack info 2-1](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/fbbea98d-d123-343b-4a5d-e373b991977d.png)

少し画面をスクロールダウンしましょう。
Instance Networkセクションで、コンパートメント、VCN、サブネットを下記のように選択していきましょう。

Graph Server Configurationセクションで確認できる, `JDBC URL FOR AUTHENTICATION`という項目は、前もって私たちが設定しておくJDBC connection stringを入力します。 そのURLはグラフサーバからアクセス可能である必要があります。

`PGQL ENGINE FOR GRAPHVIZ`はデフォルトのままでOKです。
[Figure: Stack info 2-2]
![Stack info 2-2](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/04327789-b700-ca95-a65a-27429acd8605.png)

Nextをクリックすると、今した設定の確認画面が表示されます。
`Create` をクリックして、デプロイを開始しましょう。

[Figure: Stack review]
![Stack review](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/572c53ac-1cad-8829-d771-d5cddcaa933e.png)

Marketplace imageからのデプロイはOCIリソースマネジャーによって行われます。
先ほどの設定通りに処理が実行されます。

[Figure: RM job]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/16fe3c47-ef88-b1a0-a8d7-3bab86af81ae.png)

何分か待つと、リソースマネジャーのジョブは完了します。
コンピュートインスタンスにアクセスすることで可能な状態です。
接続して、作成したグラフサーバを確認しましょう。

[Figure: Graph server compute instance]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/413e0c9c-4d3b-0820-7284-27c14db7ea83.png)

## デプロイの正常実行を確認

### PGX service

コンピュートインスタンスのコンソールから確認できるようにgraph server (PGX20201127)はrunningの状態のようです。では、お気に入りの任意のターミナルを使って、サーバに接続してPGXサーバのステータスを確認していきましょう。


```sh
systemctl status pgx
```

[Figure: PGX service status]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/e4adc419-07a1-1bd2-4b6e-2425c4802394.png)

### Java Shellツールの`opg-jshell`

下記のコマンドを使って、サーバに接続していきましょう。

```sh
opg-jshell --base_url https://localhost:7007 --username demograph
```

[Figure: jshell connect]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b647ebaf-8cc2-4a2e-8da1-875351a11468.png)

### Python clientの`opgpy`

Java Shell toolである`opgjshell`に加えて、, Oracleは、`opgpy`というPython clientもあります。もし、Pythonの方がお好みでしたら、こちらをお使いください。

```sh
opgpy --base_url https://localhost:7007 --user demograph
```

[Figure: Python client]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/7b3756e7-b1df-89f3-0803-19ddde9c44a1.png)

## PGXのグラフ

このセクションでは、Python clientである`opgpy`を使ってproperty graph serverに接続し、データベースとやりとりしていきます。

### graphを作成

```py
stmt_create = """
CREATE PROPERTY GRAPH "or"
    VERTEX TABLES (
        CUSTOMERS KEY(CUSTOMER_ID) PROPERTIES ARE ALL COLUMNS,
        PRODUCTS  KEY(STOCK_CODE)  PROPERTIES ARE ALL COLUMNS,
        PURCHASES_DISTINCT KEY(PURCHASE_ID) PROPERTIES ALL COLUMNS
    )
    EDGE TABLES (
        PURCHASES_DISTINCT as has_purchased
            KEY (PURCHASE_ID)
            SOURCE KEY(CUSTOMER_ID) REFERENCES CUSTOMERS
            DESTINATION KEY(STOCK_CODE) REFERENCES PRODUCTS
            LABEL "has_purchased"
        , PURCHASES_DISTINCT as purchased_by
            KEY (PURCHASE_ID)
            SOURCE KEY(STOCK_CODE) REFERENCES PRODUCTS
            DESTINATION KEY(CUSTOMER_ID) REFERENCES CUSTOMERS
            LABEL "purchased_by"
    )
"""
session.prepare_pgql(stmt_create).execute()
graph_or = session.get_graph("or")
graph_or
```

[Figure: create graph or]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/cbcb682a-6d68-a94a-4ed8-396a2b64abd6.png)

### graphを問い合わせる

```py
graph_or.query_pgql("SELECT ID(c), ID(p), p.description FROM or MATCH (c)-[has_purchased]->(p) WHERE c.CUSTOMER_ID = 'cust_12353'").print();
```

[Figure: query graph or]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/5d0a80bc-6276-7a19-c19a-68a2dcce3c16.png)


### graphを壊す

```py
graph_or.destroy()
session.get_graph("or")
```

[Figure: destroy graph]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/9faa3406-2c3a-cbd3-5a9a-58c3fe676eac.png)


## まとめ

今回は、marketplace imageを使って、フルに動くProperty Graph Serverを手に入れました。しかも、基本的な情報を入力し、いくつかのボタンをクリックするだけで実現することができました。もし適切な準備があれば、5分以内に実現することも可能です。めちゃくちゃ簡単でしたよね！
