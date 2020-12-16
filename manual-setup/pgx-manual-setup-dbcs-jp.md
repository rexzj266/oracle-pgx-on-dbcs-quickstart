この記事では、Oracle Cloud Infrastructure Database Systemのインスンスに Oracle Property Graph Server and clientをインストールし、環境構築をしていきます。更に、Property Graphサーバとデータベースサーバにクライアント側から正しく接続するための設定方法も紹介していきます。

上記のセットアップ手順だけではなく、2つのサンプルも用意していますので、グラフテクノロジーを体感していきましょう。

## 今回の環境

下記が、本記事での環境をまとめたリストになります。

- Oracle Property Graph Server 20.4
- Oracle Property Graph Client 20.4
- Oracle Database Software Edition: Enterprise Edition High Performance
- DB System Version: 19.9.0.0.0
- Oracle Linux 7.8 x64
- Oracle JDK 11
- Browser: Firefox

## PL/SQL Packages

Oracle Database 12.2以降であれば、Oracle Graph Server and ClientはOracle Databaseでちゃんと動きます。その前に、Oracle Graph Server and Clientの最新のPL/SQLパッケージを自分でインストールしなければなりません。
Oracle Graph Client for PL/SQLを、[こちらからダウンロード](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html)



Download `Oracle Graph Client for PL/SQL`をダウンロード後、任意のディレクトリ内で解凍して下さい。
下記のSQL文でOracle Databaseにログインしましょう。

```sql
-- SYSDBAで接続
SQL> alter session set container=<YOUR_PDB_NAME>;
SQL> @opgremov.sql
SQL> @catopg.sql
```

**注記**: 未解凍のZipディレクトリには2つのディレクトリがあると思います。一つは、Oracle Database 18c以下を使っているユーザのためのもの。もう一つが、Oracle Database 19c以降を使っているユーザ用です。DBA権限を持つデータベースユーザとして、REAME.mdファイル内のインストラクションに従って下さい。インストラクションを参考にする時は、自分のデータベースのバージョンに合っているか確認してください。これは、グラフ機能が入ったPDBを使用する際に、都度必要になります。私が作ったDBCSインスタンスは19cですから、私は`19c_and_above`のスクリプトを流していきます。


## Oracle Property Graph Server and Clientのインストール

このセクションでは、Oracle Graph Server and Client 20.4.の最新バージョンをインストールしていきます。
下記のページからインストールパッケージをダウンロード可能です。

[Oracle Graph Server and Client Downloads](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html)

### Oracle JDK 11

20.4から、Oracle Graph Server and Clientは同じJDKバージョンである11を使うようになりました。
JDK 11を先にダウンロードしていきましょう。

[Java SE Development Kit 11 Downloads](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

```sh
sudo rpm -i jdk-11.0.9_linux-x64_bin.rpm
java --version
opc@db19h graph]$
```

[Figure: java version]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/12848846-7a52-251a-dcd9-2e8842cb8b69.png)

### Oracle Property Graph Server 20.4

#### インストール

下記のコマンドでOracle Property graph Serverをインストールを始めます。

```sh
sudo rpm -i oracle-graph-20.4.0.x86_64.rpm
```

このコマンドは実行してもレスポンスは返ってきません。
下記のコマンドよりOracle Property Graph Serverをスタートさせることができます。

```sh
sudo systemctl start pgx
systemctl status pgx
sudo systemctl stop pgx
```

[Figure: PGX start & status]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/677c97fb-9a42-0e0f-2caf-9b5e7de9eb0d.png)

#### Oracle Databaseの設定

`oracle`ユーザに変更し、`sys`としてデータベースに接続します。

```sh
sudo su - oracle
sqlplus / as sysdba
```

[Figure: connect to DB]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f5cd3c63-eb09-839c-bb06-e667f50786fc.png)

PDBの`pdb1`に `demograph`というユーザを作成します。
下記のようにロールと表領域を与えていきます。
全ての表は、スキーマ`demograph`に作成され、ロードされます。

```sql
CREATE USER demograph IDENTIFIED BY <PASSWORD>;
GRANT CONNECT, resource TO demograph;
GRANT CREATE VIEW TO demograph;

CREATE ROLE graph_developer;
CREATE ROLE graph_administrator;

GRANT graph_developer TO demograph;
GRANT graph_administrator to demograph;

ALTER USER demograph QUOTA 10G ON USERS

GRANT UNLIMITED TABLESPACE TO demograph;
```

[Figure: prepare DB user `demograph`]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b7fe513d-e5cf-82e3-77d0-38b813b0bf1a.png)

#### Oracle Property Graph Serverの設定

- `graph`というシステムユーザを追加

```sh
sudo useradd graph
sudo usermod -a -G oraclegraph graph
sudo passwd graph
```

- `pgx.conf`という設定ファイルの中にJDB connection stringを追加

```sh
sudo vim /etc/oracle/graph/pgx.conf
jdbc:oracle:thin:@//db19h.sub11160238550.graphvcntokyo.oraclevcn.com:1521/pdb1.sub11160238550.graphvcntokyo.oraclevcn.com
```
connection stringはDBCSウェブコンソールから手に入ります。
もしくは、`lsnrctl status`コマンドからサービス名を入手しましょう。

ユーザ`demograph`は`pdb1`内に作成されたので,ここで私が使うconnection stringは`pdb1`になります。

[Figure: JDBC in `pgx.conf`]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f1773c56-8285-605d-037f-1925a2924460.png)

- `server.conf`という設定ファイルを編集

`enable_tls`を`false`に設定。

```sh
sudo vim /etc/oracle/graph/server.conf
```

[Figure: enable_tls in `server.conf`]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/208dd10d-8c45-ce05-1b86-7921e4582db8.png)

#### PGX serviceを再起動

```sh
sudo systemctl restart pgx
sudo systemctl status pgx
```

[Figure: restart PGX service]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/6c1f1014-bd6b-d66d-3a53-b63ee294366f.png)

### Oracle Property Graph Client 20.4

#### インストール

ユーザ`graph`に変更

```sh
sudo su - graph
```
ダウンロードしたクライアントパッケージを解凍

```sh
unzip oracle-graph-client-20.4.0.zip
```

#### Auth tokenを入手

Property Graph serverにクライアントから接続する場合、先ずauth tokenを入手する必要があります。

`curl` コマンドを使って、簡単にauth tokenを入手できます。
下記のコマンドで可能です。

```sh
curl -X POST -H 'Content-Type: application/json' -d '{"username": "<DB USER>", "password": "<PASSWORD>"}' <HOST URL>:7007/auth/token

# e.g. curl -X POST -H 'Content-Type: application/json' -d '{"username": "demograph", "password": "<PASSWORD>"}' http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007/auth/token

```

- `username`と`password`ですが、 ユーザネーム`demograph`と作成したパスワードになります。
- `HOST URL`は、connection stringからextractできます。

[Figure: get PGX token]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/8a768dbc-d34e-b682-7c8c-d90bae14226f.png)

実は、レスポンスはJSONオブジェクトとして返ってきます。レスポンスをフォーマットしてあげると、3つの要素で構成されているのが見えてきます。その要素は、トークンの中身、トークンタイプ、そしてトークンの有効時間です。
次のステップで必要なのは、`access_token`の中身になります。
また、有効時間にも目を向けてみてください。`14400` は４時間後に有効性を失うという意味です。４時間後に、このトークンで作られたセッションも無効となります。

```json
{
  "access_token": "<ENCRYPTED CONTENT>",
  "token_type": "bearer",
  "expires_in": 14400
}
```

[Figure: access token content]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/c58b28e9-2e2f-3c7c-1de8-1daaa1a5580e.png)

#### Property Graph Serverに接続

Oracle Property Graph ClientはPGX serverへの複数の接続方法を用意しています。今回のサンプルでは、 Oracle Property Graph Client shellを最初に使っていきます。

未解凍のクライアントパッケージが入っている`bin`ディレクトリに移動しましょう。 

```sh
cd /home/graph/oracle-graph-client-20.4.0/bin

./opg-jshell --base_url <HOST URL>:7007
# e.g. ./opg-jshell --base_url http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007

```

**注記: セキュリティの観点から、トークンのペーストした際には何も表示されません。ペーストして何も変化がなくても、安心してエンターボタンを押して下さいね。**
[Figure: jshell to PGX server]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/a1941270-4ae6-35e0-d107-0e6fa0b133e6.png)

`opg-jshell>`という風にコマンドプロンプトが変化したのを確認できたら、サーバに接続できたということです。

## Graph サンプル - HR

### HRというデータベーススキーマの準備



Download the HR create script from [ここ](https://github.com/rexzj266/oracle-pgx-scripts)からHRスキーマと作成するスクリプトをダウンロードして、`pdb1`のユーザ`demograph`でHRスキーマを作成して下さい。

```sql
sqlplus demograph/<PASSWORD>@db19h.sub11160238550.graphvcntokyo.oraclevcn.com:1521/pdb1.sub11160238550.graphvcntokyo.oraclevcn.com

@HR_create_hr_objects.sql
```

### property graph表を作成

データベースに接続するためにjshellから下記のスクリプトを実行して下さい。

```java
var jdbcUrl = "jdbc:oracle:thin:@//db19h.sub11160238550.graphvcntokyo.oraclevcn.com:1521/pdb1.sub11160238550.graphvcntokyo.oraclevcn.com"
var user = "demograph"
var pass = "<PASSWORD>"
var conn = DriverManager.getConnection(jdbcUrl, user, pass)

conn.setAutoCommit(false)
```

[Figure: jshell connection]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/fe219014-6edd-a527-e586-0eb1c6df4128.png)

PGQL接続のために下記のスクリプトを実行して下さい。
このPGQL接続を通じて、用意してある`create.pgql`スクリプトを実行していきます。
このスクリプトで、先ほど作成したHRスキーマのデータベース表も基にproperty graph表を作成することができます。

[ここ](https://github.com/rexzj266/oracle-pgx-scripts)から`create.pgql`を入手できます。

```java
var pgql = PgqlConnection.getConnection(conn)
pgql.prepareStatement(Files.readString(Paths.get("/home/graph/create.pgql"))).execute()
```

[Figure: pgql connection]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/2f7c7ea8-e9f3-b296-a64a-fec11803b83b.png)

[Figure: `create.pgql`]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/0ff4cebc-1df2-f5af-5824-a1171ababcac.png)

さて、**VERTEX TABLES**と**EDGE TABLES**など、いくつかのproperty graph表を作成して参りました。

### データベースから問合せ

ラムダファンクション`query`を定義するために、jshellから下記のスクリプトを実行して下さい。
このファンクションは、後ほど問合せを実行する際に役立ちます。

```java
Consumer < String > query = q -> {
    try (var s = pgql.prepareStatement(q)) {
        s.execute();
        s.getResultSet().print();
    } catch (Exception e) {
        throw new RuntimeException(e);
    }
}
```

[Figure: lambda `query`]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/ccdaef6c-13e6-eae5-f8da-213274a95d42.png)

下記のスクリプトで`hr graph`の頂点の数を問合せる。

```java
query.accept("select count(v) from hr match (v)")
```

[Figure: query vertices]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/95b4390e-20f9-d0ce-fe02-e7c3412471f6.png)

下記のスクリプトで、エッジの数を問合せる。

```java
query.accept("select count(e) from hr match ()-[e]->()")
```

降順でマネージャの情報と彼らの給料について問合せる。

```java
query.accept("select distinct m.FIRST_NAME, m.LAST_NAME,m.SALARY from hr match (v:EMPLOYEES)-[:WORKS_FOR]->(m:EMPLOYEES) order by m.SALARY desc")
```

[Figure: query manager info]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/94757b12-9041-0ee5-4395-0e4354322773.png)

### メモリから問い合わせ


Property graph serverにデータをロードすると、問合せのスピードだけでなく、問合せのキャパシティも改善されます。 メモリにロードすることで、より応用的なアルゴリズムを使った問合せもできるようになります。つまり、データからもっと価値のある結果を手に入れることができるのです。


下記のスクリプトで、メモリ上のgraph構造を定義します。

```java
Supplier <GraphConfig> pgxConfig = () -> {
    return
    GraphConfigBuilder.forPropertyGraphRdbms()
    .setJdbcUrl(jdbcUrl)
    .setUsername(user)
    .setPassword(pass)
    .setName("hr")
    .addVertexProperty("COUNTRY_NAME", PropertyType.STRING)
    .addVertexProperty("DEPARTMENT_NAME", PropertyType.STRING)
    .addVertexProperty("FIRST_NAME", PropertyType.STRING)
    .addVertexProperty("LAST_NAME", PropertyType.STRING)
    .addVertexProperty("EMAIL", PropertyType.STRING)
    .addVertexProperty("PHONE_NUMBER", PropertyType.STRING)
    .addVertexProperty("SALARY", PropertyType.DOUBLE)
    .addVertexProperty("MIN_SALARY", PropertyType.DOUBLE)
    .addVertexProperty("MAX_SALARY", PropertyType.DOUBLE)
    .addVertexProperty("STREET_ADDRESS", PropertyType.STRING)
    .addVertexProperty("POSTAL_CODE", PropertyType.STRING)
    .addVertexProperty("CITY", PropertyType.STRING)
    .addVertexProperty("STATE_PROVINCE", PropertyType.STRING)
    .addVertexProperty("REGION_NAME", PropertyType.STRING)
    .setPartitionWhileLoading(PartitionWhileLoading.BY_LABEL)
    .setLoadVertexLabels(true)
    .setLoadEdgeLabel(true)
    .setKeystoreAlias("alias")
    .build();
}
```

[Figure: define graph structure in memory]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/9bbc6690-82e6-b3ca-1f0e-7220ce206a14.png)

下記のスクリプトで、メモリ上にgraphを作成します。 

```java
var graph = session.readGraphWithProperties(pgxConfig.get())
```

[Figure: create graph in memory]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f362e6f2-7a18-2159-758d-a2625206b44a.png)

下記のスクリプトで、pagerankアルゴリズムを使ったグラフ分析を行います。


```java
analyst.pagerank(graph)
```

[Figure: analyze graph with pagerank]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/64a69ef3-f7c2-36b3-2fe4-abdf9e192e96.png)

下記のスクリプトで、pagerank結果の最初の１０人の従業員を問合せて、降順表示します。

```java
session.queryPgql("select m.FIRST_NAME, m.LAST_NAME,m.pagerank from hr match (m:EMPLOYEES) order by m.pagerank desc limit 10").print().close()
```

[Figure: query pagerank result]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/e20f9e51-1eae-fed7-1413-eb63c0a39136.png)

## グラフサンプル - ネット通販

このセクションでは、ネット通販の情報からいくつかデータベースの表を作成していきます。
また、property graph serverにグラフも作成していきます。

サーバへの接続時にkeystoreを使っていきます。kyestoreを使うことで、平文トークンがネットワーク経由で送信されることを防ぐことができます。セキュリティ面の更なる強化を期待できます。

### Online Retail表の作成

実を言うと、このセクションは、Yamanakaさんが作成したサンプルに沿っているに過ぎません。Yamanakaさんは、Oracleでspatial and graph製品のプロダクトマネジャーとしてアジアパシフィック担当されている方です。
このセクションで使用する全てのスクリプトは、[Yamanakaさんのgithubリポジトリ](https://github.com/ryotayamanaka/oracle-pg/tree/master/graphs/online_retail)からダウンロードすることができます。

ダウンロードが必要なファイルを下記にまとめています。

- `create_table.sql`
- `create_table_normalized.sql`
- `sqlldr.ctl`
- `config-tables-distinct.json`

上記のファイルの中身を確認して、ご自身の設定に合わせてアップデートして下さい。 `config-tables-distinct.json`のJDB connection string、user name、keystore aliasには注意して下さい。また、`sqlldr.ctl`のinput file pathにも注意です。

データベースにロード予定のデータに関して、[こちらのページ](https://github.com/ryotayamanaka/oracle-pg/tree/master/graphs/online_retail)の`Download Dataset`セクションを参考にして下さい。

基本的に、online retail表を作成するには、下記の5つのステップを踏んで行きます。

1. data.csvを用意して、上記の全てのスクリプトをダウンロードする
2. `oracle`に変更し、`demograph`ユーザでpdb1にログインする
3. use `create_table.sql`を使って、`transactions`表を作成する
4. SQL*Loaderを使ってdata.csv into `transactions`表にdata.csvをロードする
5. `create_table_normalized.sql`を使って、関係するいくつかの表を作成する

必要な表を作成できれば、データベースの表の準備は完了です。

### `keystore`の準備

`keytool`は、keyの管理とそれらのceritificateをするためのJavaユーティリティです。このJavaユーティリティは、`keystore`を生成するために今回使用します。

下記のコマンドで、`keystores`ディレクトリを作成し、`keystore`を生成します。

```sh
cd
mkdir keystores && cd keystores
keytool -importpass -alias demograph -keystore keystore.p12
```

`Enter keystore password:`と表示されたら、keystore用のパスワードを入力して下さい。その後、`Enter the password to be stored:`と表示されたら、格納したいパスワードを入力して下さい。この記事では、 データベースユーザの`demograph`のパスワードを入力していきましょう。

[Figure: generate keystore]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/6686f7ea-438e-fedd-aaf4-b25e4869fbbc.png)

### `keystore`で接続

To connect from jshellからデータベースに接続するためには、auth tokenが必要になります。 
やっていきましょう。

```sh
curl -X POST -H 'Content-Type: application/json' -d '{"username": "<DB USER>", "password": "<PASSWORD>"}' <HOST URL>:7007/auth/token

# e.g. curl -X POST -H 'Content-Type: application/json' -d '{"username": "demograph", "password": "<PASSWORD>"}' http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007/auth/token
```
そして、下記のコマンドで、サーバにkeystoreを使った接続を行います。

```sh
cd /home/graph/oracle-graph-client-20.4.0/bin
./opg-jshell --base_url http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007 --secret_store /home/graph/keystores/keystore.p12
```
いま手に入れたauth tokenを入力して下さい。
その後、`enter password for keystore /home/graph/keystores/keystore.p12:`と表示されたら、keystore用のパスワードを入力して下さい。

[Figure: jshell connect with keystore ]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b2c859c1-c74f-b5b0-5485-5cbdda6f8be5.png)

### 事前定義された設定ファイルでPGXにグラフを作成

下記のスクリプトで、事前定義された設定ファイルである`config-tables-distinct.json`を使って、property graph serverにグラフを作成します。

```java
var graph = session.readGraphWithProperties("/home/graph/config-tables-distinct.json", "Online Retail");
```

[Figure: load Online Retail graph]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/34ec537a-5790-eb48-2fea-0a76726649b4.png)

下記のスクリプトで、カスタマーIDが`cust_12353`の顧客の購買履歴を問合せる

```java
graph.queryPgql(" SELECT ID(c), ID(p), p.description FROM MATCH (c)-[has_purchased]->(p) WHERE ID(c) = 'cust_12353' ").print();
```

[Figure: query in online retail graph]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/ab888499-e06f-aef0-9ce9-2ec21348b115.png)

下記のスクリプトで、personalizedPagerankを使って、カスタマーIDが`cust_12353`の顧客を分析する

```java
var vertex = graph.getVertex("cust_12353");
analyst.personalizedPagerank(graph, vertex)
```

[Figure: personoalizedPagerank]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/01581cc6-ae3f-c12b-7f19-d6723e05f275.png)

下記のスクリプトで、トップ10の製品を問合せる

```java
graph.queryPgql(
    "  SELECT ID(p), p.description, p.pagerank " +
    "  MATCH (p) " +
    "  WHERE LABEL(p) = 'Product' " +
    "    AND NOT EXISTS ( " +
    "     SELECT * " +
    "     MATCH (p)-[:purchased_by]->(a) " +
    "     WHERE ID(a) = 'cust_12353' " +
    "    ) " +
    "  ORDER BY p.pagerank DESC" +
    "  LIMIT 10"
).print();
```

[Figure: top10]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/aafc7ea2-bf73-1111-a10d-5f2ee33cb64c.png)

### GraphVizの問合せ

ここまで、コマンドラインインタフェースである`jshell`を使って問合せを行ってきました。
しかし、ビルドインのグラフィックインターフェースである`GraphViz`を使って問合せを行うことができるんです。

GraphVizはブラウザベースのインターフェースで、`<HOST URL>:7007/ui`というURLでアクセスできます。

ログイン画面で、usernameは`demograph`、passwordはご自身で設定されたものを入力して下さい。

下記のスクリプトで、セッションIDを取得できます。セッションが切れていない限り、そのセッションIDを入力すれば、そのセッションのグラフにアクセスすることができます。

```java
session.getId();
```

[Figure: session ID]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/8581c50f-3994-7660-e776-172cec5b3cae.png)

[Figure: GraphViz Login]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/9eb0a81c-f5e4-4586-8d87-4f7068357b4d.png)

ログイン後、下記のようにデフォルトページを確認できます。

[Figure: GraphViz Query default]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/43cd49e0-74e8-8e92-054e-a6b99b087198.png)

ここでは、複雑な問合せを実行できますし、GraphVizは問合せ結果をインタラクティブなグラフとして表示してくれます。

```java
SELECT *
MATCH (c1)-[e1]->(p1)<-[e2]-(c2)-[e3]->(p2)
WHERE ID(c1) = 'cust_12353'
  AND ID(p2) = 'prod_23166'
  AND ID(c1) != ID(c2)
  AND ID(p1) != ID(p2)
```

[Figure: GraphViz Query sample]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/11597b18-3753-2856-cc6a-0bfe720bf07f.png)

また、カスタムセッティングをアップロードすることで、グラフチャートの表現かカスタマイズすることが可能です。例えば、下記のスクリーンショットでは、`highlight.json`と言う設定ファイルをアップロードしました。チャートがさらに直感的に理解できるように表示されています。

[Figure: GraphViz upload highlight.json]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/047ba6b6-19f3-009e-92b0-08cf6301dd9e.png)

[Figure: GraphViz highlight graph]
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/42bcb84d-245e-c541-5525-0b5e6b239e1b.png)

## まとめ

この記事では、Oracle DBCSインスタンスにOracle Property Graph server and clientをセットアップする方法を紹介しました。 **※the server and clientはどんなマシーン上にもインストールすることができます。**

また、グラフを体感するために、HRとOnline Retailという2つのサンプルを作成しました。

- グラフの作成方法
- グラフの問合せ方法
- メモリ上にグラフをロードする方法
- 複雑な問合せを実行する方法
- GraphVizの使い方

この記事を読んで頂きまして、ありがとうございました。
Oracle Property Graphのテクノロジーの基本的な理解と、Oracle Property Graph serverで遊び始められる環境を持ち帰って頂ければ、幸いです。もし、もっと知りたいと言う方がいらっしゃいましたら、下記の参考文献もご参照下さいね。

## 参考文献

- [Oracle as a Property Graph](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features.html)
- [Oracle Property Graph Developer’s Guide](https://docs.oracle.com/en/database/oracle/oracle-database/20/spgdg/lot.html)
- [ryotayamanaka/oracle-pg](https://github.com/ryotayamanaka/oracle-pg)
- [Oracle Property Graph Server Installation](https://docs.oracle.com/en/database/oracle/oracle-database/20/spgdg/property-graph-overview-spgdg.html#GUID-CCF6BB1E-3C8F-4746-A938-BA3E6EDC9541)
