# How to setup and start to use Oracle Property Graph server

In this article, I will introduce how to install and setup Oracle Property Graph Server and client in an Oracle Cloud Infrastructure Database System instance. We will also talk about how to configure them properly to make connection from the client to the property graph server and to the database server.

Besides the topic of setting up, we will also prepare 2 samples to experience the advantage of graph technology.

## Environment

This is a list of environment components for this article.

- Oracle Property Graph Server 20.4
- Oracle Property Graph Client 20.4
- Oracle Database Software Edition: Enterprise Edition High Performance
- DB System Version: 19.9.0.0.0
- Oracle Linux 7.8 x64
- Oracle JDK 11
- Browser: Firefox

## PL/SQL Packages

Oracle Graph Server and Client will work with Oracle Database 12.2 onward. However, you must install the updated PL/SQL packages that are part of the [Oracle Graph Server and Client download](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html).

Download `Oracle Graph Client for PL/SQL` and unzip the file into a directory of your choice.
Login to the Oracle Database and execute following statements

```sql
-- Connect as SYSDBA
SQL> alter session set container=<YOUR_PDB_NAME>;
SQL> @opgremov.sql
SQL> @catopg.sql
```

Note: there are two directories in the unzipped directory, one for users with Oracle Database 18c or below, and one for users with Oracle Database 19c or above. As a database user with DBA privilges, follow the instructions in the README.md file in the appropriate directory (that matches your database version). This has to be done for every PDB you will use the graph feature in. The DBCS instance I created is 19c, so I should execute the scripts in `19c_and_above`.

## Oracle Property Graph Server and Client Installation

In this section, we will install the latest version of Oracle Graph Server and Client 20.4.
We can download the installation package from following page.

[Oracle Graph Server and Client Downloads](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html)

### Oracle JDK 11

From 20.4, Oracle Graph Server and Client use the same JDK version 11, so we only need to install JDK 11 as prerequisite.

[Java SE Development Kit 11 Downloads](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

```sh
sudo rpm -i jdk-11.0.9_linux-x64_bin.rpm
java --version
opc@db19h graph]$
```

[Figure: java version]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/12848846-7a52-251a-dcd9-2e8842cb8b69.png)

### Oracle Property Graph Server 20.4

#### Install

Execute following command to install Oracle Property graph Server.

```sh
sudo rpm -i oracle-graph-20.4.0.x86_64.rpm
```

There is no any response after we execute this command. We can start and check the Oracle Property Graph Server service with following commands.

```sh
sudo systemctl start pgx
systemctl status pgx
sudo systemctl stop pgx
```

[Figure: PGX start & status]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/677c97fb-9a42-0e0f-2caf-9b5e7de9eb0d.png)

#### Configuration in Oracle Database

Switch user to `oracle` and connect to Oracle Database as `sys`.

```sh
sudo su - oracle
sqlplus / as sysdba
```

[Figure: connect to DB]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f5cd3c63-eb09-839c-bb06-e667f50786fc.png)

Create database user `demograph` in PDB `pdb1`, grant role and tablespace accordingly.
All the tables will be created and loaded into this schema `demograph`.

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

#### Configuration in Oracle Property Graph Server

- Add a new system user `graph`.

```sh
sudo useradd graph
sudo usermod -a -G oraclegraph graph
sudo passwd graph
```

- Add JDBC connection string in the configuration file `pgx.conf`.

```sh
sudo vim /etc/oracle/graph/pgx.conf
jdbc:oracle:thin:@//db19h.sub11160238550.graphvcntokyo.oraclevcn.com:1521/pdb1.sub11160238550.graphvcntokyo.oraclevcn.com
```

We can get the connection string from the DBCS web console, or by command `lsnrctl status` to get the service name.

Since the user `demograph` was created in `pdb1`, so the connection string I am using here is to `pdb1`.

[Figure: JDBC in `pgx.conf`]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f1773c56-8285-605d-037f-1925a2924460.png)

- Edit configuration file `server.conf`

Set `enable_tls` to be `false`.

```sh
sudo vim /etc/oracle/graph/server.conf
```

[Figure: enable_tls in `server.conf`]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/208dd10d-8c45-ce05-1b86-7921e4582db8.png)

#### Restart PGX service

```sh
sudo systemctl restart pgx
sudo systemctl status pgx
```

[Figure: restart PGX service]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/6c1f1014-bd6b-d66d-3a53-b63ee294366f.png)

### Oracle Property Graph Client 20.4

#### Install

Switch to user `graph`

```sh
sudo su - graph
```

Unzip the downloaded client package.

```sh
unzip oracle-graph-client-20.4.0.zip
```

#### Get auth token

To connect client to the Property Graph server, we need to get the auth token first.

We can use `curl` command to get the auth token in an easy way. The command is in following format.

```sh
curl -X POST -H 'Content-Type: application/json' -d '{"username": "<DB USER>", "password": "<PASSWORD>"}' <HOST URL>:7007/auth/token

# e.g. curl -X POST -H 'Content-Type: application/json' -d '{"username": "demograph", "password": "<PASSWORD>"}' http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007/auth/token

```

- `username` and `password` are the database user `demograph` and its password we created previously.
- `HOST URL` can be extracted from the connection string.

[Figure: get PGX token]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/8a768dbc-d34e-b682-7c8c-d90bae14226f.png)

The response is a JSON object actually, if we format it we can see that there are 3 items in the response. They represent the token content, token type and token expiration time respectively. What we need in next step is the content of `access_token`. Please also pay attention to the expiration time. `14400` means in 4 hours later, this token will be expired, the session created with this token will be expired as well.

```json
{
  "access_token": "<ENCRYPTED CONTENT>",
  "token_type": "bearer",
  "expires_in": 14400
}
```

[Figure: access token content]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/c58b28e9-2e2f-3c7c-1de8-1daaa1a5580e.png)

#### Connect to the Property Graph Server

Oracle Property Graph Client provides several ways to connect to the PGX server. We use Oracle Property Graph Client shell first in this sample.

Go to the `bin` directory of the unzipped client package.

```sh
cd /home/graph/oracle-graph-client-20.4.0/bin

./opg-jshell --base_url <HOST URL>:7007
# e.g. ./opg-jshell --base_url http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007

```

**Note: for security reason, there is no any character display when you paste the token, so don't doubt yourself, just press enter should be fine.**

[Figure: jshell to PGX server]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/a1941270-4ae6-35e0-d107-0e6fa0b133e6.png)

If you can see the command prompt changed to be `opg-jshell>`, then you have connected to the server successfully.

## Graph Sample - HR

### Prepare database schema HR

Download the HR create script from [here](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart) and create HR schema in `pdb1` user `demograph`

```sql
sqlplus demograph/<PASSWORD>@db19h.sub11160238550.graphvcntokyo.oraclevcn.com:1521/pdb1.sub11160238550.graphvcntokyo.oraclevcn.com

@HR_create_hr_objects.sql
```

### Create property graph table

Execute following statements in jshell to create connection to the database.

```java
var jdbcUrl = "jdbc:oracle:thin:@//db19h.sub11160238550.graphvcntokyo.oraclevcn.com:1521/pdb1.sub11160238550.graphvcntokyo.oraclevcn.com"
var user = "demograph"
var pass = "<PASSWORD>"
var conn = DriverManager.getConnection(jdbcUrl, user, pass)

conn.setAutoCommit(false)
```

[Figure: jshell connection]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/fe219014-6edd-a527-e586-0eb1c6df4128.png)

Execute following statements to create a PGQL connection. Through this PGQL connection, we will execute the prepared script `create.pgql` to create property graph tables based on the database tables in HR schema we created previously.

You can get the `create.pgql` from [here](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart).

```java
var pgql = PgqlConnection.getConnection(conn)
pgql.prepareStatement(Files.readString(Paths.get("/home/graph/create.pgql"))).execute()
```

[Figure: pgql connection]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/2f7c7ea8-e9f3-b296-a64a-fec11803b83b.png)

[Figure: `create.pgql`]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/0ff4cebc-1df2-f5af-5824-a1171ababcac.png)

Now, we have created some property graph tables, including **VERTEX TABLES** and **EDGE TABLES**.

### Query from database

Execute following statements in jshell to define a lambda function `query`, we can use this function to perform queries later.

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

Query the number of vertices in the `hr graph` with following statement.

```java
query.accept("select count(v) from hr match (v)")
```

[Figure: query vertices]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/95b4390e-20f9-d0ce-fe02-e7c3412471f6.png)

Query the number of edge with following statement.

```java
query.accept("select count(e) from hr match ()-[e]->()")
```

Query the information of the manager and sort them in descending order of the salary.

```java
query.accept("select distinct m.FIRST_NAME, m.LAST_NAME,m.SALARY from hr match (v:EMPLOYEES)-[:WORKS_FOR]->(m:EMPLOYEES) order by m.SALARY desc")
```

[Figure: query manager info]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/94757b12-9041-0ee5-4395-0e4354322773.png)

### Query from memory

Loading the data into the property graph server can improve not only the query speed, but also enhance the query capability. By loading in memory, we can utilize more advanced algorithms to perform the queries. Therefore we can get more valuable results from the data.

Execute following statement to define the graph structure in memory.

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

Execute following statement to create the graph in memory.

```java
var graph = session.readGraphWithProperties(pgxConfig.get())
```

[Figure: create graph in memory]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f362e6f2-7a18-2159-758d-a2625206b44a.png)

Execute following statement to analyse the graph with pagerank algorithm.

```java
analyst.pagerank(graph)
```

[Figure: analyze graph with pagerank]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/64a69ef3-f7c2-36b3-2fe4-abdf9e192e96.png)

Execute following statement to query and print out the first 10 employee information which are sorted in descending order of pagerank results.

```java
session.queryPgql("select m.FIRST_NAME, m.LAST_NAME,m.pagerank from hr match (m:EMPLOYEES) order by m.pagerank desc limit 10").print().close()
```

[Figure: query pagerank result]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/e20f9e51-1eae-fed7-1413-eb63c0a39136.png)

## Graph Sample - Online Retail

In this section, we will create some database tables with online retail information and create graph in the property graph server accordingly.

We will also use keystore when connecting to the server. In this way, there will be no plaintext token being transferred through the network. The security could be ensured further.

### Create Online Retail tables

Actually this section is just another version of the sample provided by Mr. Yamanaka who is the Oracle Product Manager in Asia-Pacific for spatial and graph technologies. We can download all the scripts used in this section from [Mr. Yamanaka's github repository](https://github.com/ryotayamanaka/oracle-pg/tree/master/graphs/online_retail).

Below is a list of the files we need to download.

- `create_table.sql`
- `create_table_normalized.sql`
- `sqlldr.ctl`
- `config-tables-distinct.json`

Please check the content of these files and update them according to your settings. In `config-tables-distinct.json` we need to pay attention to the JDBC connection string, username and keystore alias. In `sqlldr.ctl`, we need to pay attention to the input file path.

Regarding to the data that will be loaded into the database, please refer to the `Download Dataset` section on [this page](https://github.com/ryotayamanaka/oracle-pg/tree/master/graphs/online_retail).

Basically, the steps to create the online retail tables are:

1. download all the scripts mentioned above and prepare data.csv
2. switch user to `oracle` and login to pdb1 with database user `demograph`
3. use `create_table.sql` to create the `transactions` table
4. use SQL\*Loader to load the data.csv into `transactions` table
5. use `create_table_normalized.sql` to create related tables

Once the tables are created, the database table preparation is complete.

### Prepare `keystore`

`keytool` is a Java utility to help us to manage the key and certificate. We will use this tool to generate the `keystore`.

Execute following commands to create a `keystores` directory and generate `keystore` accordingly.

```sh
cd
mkdir keystores && cd keystores
keytool -importpass -alias demograph -keystore keystore.p12
```

Input the password of this keystore when prompting `Enter keystore password:`, then input the password you want to store when prompting `Enter the password to be stored:`. In our case, it should be the password of database uesr `demograph`.

[Figure: generate keystore]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/6686f7ea-438e-fedd-aaf4-b25e4869fbbc.png)

### Connect with `keystore`

To connect from jshell to the database we still need the auth token. Let's get it first.

```sh
curl -X POST -H 'Content-Type: application/json' -d '{"username": "<DB USER>", "password": "<PASSWORD>"}' <HOST URL>:7007/auth/token

# e.g. curl -X POST -H 'Content-Type: application/json' -d '{"username": "demograph", "password": "<PASSWORD>"}' http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007/auth/token
```

Then, we can execute following command to connect to the server with the keystore.

```sh
cd /home/graph/oracle-graph-client-20.4.0/bin
./opg-jshell --base_url http://db19h.sub11160238550.graphvcntokyo.oraclevcn.com:7007 --secret_store /home/graph/keystores/keystore.p12
```

Input the auth token we got just now, and input the password of the keystore when prompting `enter password for keystore /home/graph/keystores/keystore.p12:`

[Figure: jshell connect with keystore ]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b2c859c1-c74f-b5b0-5485-5cbdda6f8be5.png)

### Create graph into PGX with pre-defined configuration file

Following statement uses the pre-defined configuration file `config-tables-distinct.json` to create a graph in the property graph server.

```java
var graph = session.readGraphWithProperties("/home/graph/config-tables-distinct.json", "Online Retail");
```

[Figure: load Online Retail graph]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/34ec537a-5790-eb48-2fea-0a76726649b4.png)

Execute following statement to query the purchase records of customer whose ID is `cust_12353`.

```java
graph.queryPgql(" SELECT ID(c), ID(p), p.description FROM MATCH (c)-[has_purchased]->(p) WHERE ID(c) = 'cust_12353' ").print();
```

[Figure: query in online retail graph]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/ab888499-e06f-aef0-9ce9-2ec21348b115.png)

Following statement uses personalizedPagerank to analyse customer whose ID is `cust_12353`.

```java
var vertex = graph.getVertex("cust_12353");
analyst.personalizedPagerank(graph, vertex)
```

[Figure: personoalizedPagerank]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/01581cc6-ae3f-c12b-7f19-d6723e05f275.png)

Following statement queries the top10 products.

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

### Query in GraphViz

Until now, we only query in the command line interface - `jshell`. Actually, we can also query in the built-in graphic interface - `GraphViz`.

GraphViz is a browser based interface, the URL to visit it is `<HOST URL>:7007/ui`.

On the login page, username is `demograph` in our case. You should know your password.

By execute following statement, we can get the session ID. If we input the session ID, we can visit the same graphs in that session, as long as you don't close the session.

```java
session.getId();
```

[Figure: session ID]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/8581c50f-3994-7660-e776-172cec5b3cae.png)

[Figure: GraphViz Login]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/9eb0a81c-f5e4-4586-8d87-4f7068357b4d.png)

After login, we should see a default page as below.

[Figure: GraphViz Query default]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/43cd49e0-74e8-8e92-054e-a6b99b087198.png)

We can perform a complex query and GraphViz will show us a interactive graph of the query result.

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

We can also upload custom settings to customize the output graph chart. For example, in the screenshot below, we upload a setting file called `highlight.json` to show the chart in a more intuitive way.

[Figure: GraphViz upload highlight.json]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/047ba6b6-19f3-009e-92b0-08cf6301dd9e.png)

[Figure: GraphViz highlight graph]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/42bcb84d-245e-c541-5525-0b5e6b239e1b.png)

## Conclusion

In this article, we introduced how to setup the Oracle Property Graph server and client in Oracle DBCS instance. **But actually, we can definitely install the server and client on any other machines.**

We also created 2 samples: HR and Online Retail to experience

- how to create graph
- how to query graph
- how to load graph into memory
- how to perform complex query
- how to use GraphViz

I hope that after reading this article, you can have a basic understanding of Oracle Property Graph technologies and can start to play with Oracle Property Graph server. If you have more interesting on it, please check the references below.

## References

- [Oracle as a Property Graph](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features.html)
- [Oracle Property Graph Developer’s Guide](https://docs.oracle.com/en/database/oracle/oracle-database/20/spgdg/lot.html)
- [ryotayamanaka/oracle-pg](https://github.com/ryotayamanaka/oracle-pg)
- [Oracle Property Graph Server Installation](https://docs.oracle.com/en/database/oracle/oracle-database/20/spgdg/property-graph-overview-spgdg.html#GUID-CCF6BB1E-3C8F-4746-A938-BA3E6EDC9541)
