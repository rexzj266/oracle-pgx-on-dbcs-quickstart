# 从应用程序市场(Marketplace)部署Oracle Property Graph Server


在上一篇文章 - [如何设置和开始使用Oracle Property Graph服务器](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart/blob/master/manual-setup/pgx-manual-setup-dbcs.md)中，我们讨论了如何在DBCS实例上设置和开始使用Oracle Graph 服务器和客户端。但是所有步骤都是手动完成的，而且Graph 服务与数据库实例位于同一服务器（VM）中。 从最佳实践的角度来看，这并不是一个好方法。Oracle Property Graph 服务与数据库实例应部署在单独的服务器中，以避免彼此干扰。

## 先决条件

在本文中, Oracle Property Graph 服务器将与 DBCS 实例分开部署, 因此, 我们假设一个单独的 DBCS 实例已部署完成。随后, 我们将对这个 DBCS 实例进行一些必要的设置, 以使其可以与 Graph 服务器协同工作。

### Oracle数据库中的设置

本节将阐述在 DBCS 实例中进行的必要设置。

首先，连接进入 DBCS 实例，切换用户为 `oracle` 并作为 `sysdba` 连接进入数据库。

```sh
sudo su - oracle
sqlplus / as sysdba
```

[Figure: connect to DB]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f5cd3c63-eb09-839c-bb06-e667f50786fc.png)

- PL/SQL Packages

Oracle Graph 服务器和客户端可以与 Oracle Database 12.2 之后的版本协同工作. 但是, 我们需要在数据库中安装/更新必要的 PL/SQL packages. 这些 PL/SQL packages 可以在 [此处](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html) 下载.

下载最新版的 `Oracle Graph Client for PL/SQL` 文件，并解压缩到任意文件夹后, 连接进入数据库并执行下列命令.

```sql
-- Connect as SYSDBA
SQL> alter session set container=<YOUR_PDB_NAME>;
SQL> @opgremov.sql
SQL> @catopg.sql
```

注意：解压缩后会有两个目录，一个目录服务于使用Oracle Database 18c或更低版本的用户，一个目录服务于使用Oracle Database 19c或更高版本的用户。 请遵循相应目录（与您的数据库版本匹配）中README.md文件中的说明来完成操作。 这些脚本需要在每个将要使用 Graph 功能的 PDB 中执行。我创建的DBCS实例为19c，因此我应该执行 `19c_and_above` 中的脚本。

- user & roles

在 PDB 中创建数据库用户 `demograph`，并设置相应的 role 和 tablespace。
所有表将在该用户 `demograph` 中创建。

```sql
CREATE USER demograph IDENTIFIED BY <PASSWORD>;

GRANT alter session TO demograph;
GRANT create procedure TO demograph;
GRANT create sequence TO demograph;
GRANT create session TO demograph;
GRANT create table TO demograph;
GRANT create trigger TO demograph;
GRANT create type TO demograph;
GRANT create view TO demograph;

CREATE ROLE graph_developer;
CREATE ROLE graph_administrator;

GRANT graph_developer TO demograph;
GRANT graph_administrator to demograph;

ALTER USER demograph QUOTA 10G ON USERS

GRANT UNLIMITED TABLESPACE TO demograph;
```

[Figure: prepare DB user `demograph`]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b7fe513d-e5cf-82e3-77d0-38b813b0bf1a.png)

### 创建 Online Retail 示例

稍后，我们将使用几个 Online Retail 相关的示例表来体验部署完成的 Oracle Property Graph 服务。请参考另一篇文章 [Create and populate the Online Retail tables](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart/blob/master/create-and-populate-online-retail-tables/create-and-populate-online-retail-tables.md) 来创建这些表。

## 从应用程序市场(Marketplace)进行快速部署

访问 OCI 应用程序市场并在搜索框中输入 `graph` 作为关键字， 在搜索结果中我们可以看见 Oracle Property Graph Server & Client 镜像。如下图所示。

[Figure: Marketplace]

![marketplace.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/2c5c52eb-7115-a06f-b036-a95b7beb2631.png)

[Figure: PGX in marketplace]

![PGX in marketplace](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/bbb9ffc7-8ae0-cc11-71be-189759c4a359.png)

在开始部署前，请认真阅读 `Overview` 和 `Usage Instruction` 中的内容。
选择版本（20.4.0）及 Compartment 之后即可点击 `Lunch Stack` 开始部署。

[Figure: Launch Stack]

![Launch Stack](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/8f02d3e3-1754-82b0-4db7-6ed5e8541964.png)

输入该 Stack 的名称及描述。可以看见 Compartment 已经被默认选择。

[Figure: Stack info 1]

![Stack info 1](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/622120a0-f16f-50c7-d09a-1cd976f5b859.png)

点击 Next，输入更多详细信息。

在 Oracle Graph Server Compute Instance 部分，输入下列信息。

- `RESOURCE NAME PREFIX` 将帮助我们识别所创建的资源
- `ORACLE GRAPH SERVER COMPARTMENT` 允许我们选择在哪个 Compartment 中创建 Graph 服务器
- `ORACLE GRAPH SERVER SHAPE` 允许我们选择不同 Shape 的服务器来部署 Graph 服务。 关于不同 Shape 的详细信息， 请参考 [VM Shape](https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm#vmshapes)页面。
- `SSH PUBLIC KEY` 是我们用来远程连接进入 Graph 服务器的公共秘钥。

[Figure: Stack info 2-1]

![Stack info 2-1](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/fbbea98d-d123-343b-4a5d-e373b991977d.png)

向下滚动页面，在 Instance Network 部分，我们需要选择 Compartment，VCN，以及相应的 Subnet。

在 Graph Server Configuration 部分，`JDBC URL FOR AUTHENTICATION` 中应填入连接到我们创建好的数据库的 JDBC 连接字符串。`PGQL ENGINE FOR GRAPHVIZ` 我们保留默认设置。

[Figure: Stack info 2-2]

![Stack info 2-2](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/04327789-b700-ca95-a65a-27429acd8605.png)

点击 Next 并查看我们所选择的设置内容之后，我们就可以点击 `Create` 来开始 Oracle Property Graph 服务器的部署。

[Figure: Stack review]

![Stack review](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/572c53ac-1cad-8829-d771-d5cddcaa933e.png)

从应用程序市场进行部署的工作其实是由 OCI Resource Manager 来完成的。我们配置好 Stack 之后，一个作业(Job)将会根据我们配置的信息来执行。

[Figure: RM job]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/16fe3c47-ef88-b1a0-a8d7-3bab86af81ae.png)

几分钟之后，作业执行完毕，我们则可以访问 OCI Compute Instance 页面来查看刚刚创建好的实例，Oracle Property Graph 服务已经在其中部署完成。

[Figure: Graph server compute instance]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/413e0c9c-4d3b-0820-7284-27c14db7ea83.png)

## 验证部署

### PGX 服务

SSH 远程连接进入刚刚部署好的 Graph 服务器，执行下面的命令我们可以查看当前 PGX 服务的状态。

```sh
systemctl status pgx
```

[Figure: PGX service status]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/e4adc419-07a1-1bd2-4b6e-2425c4802394.png)

### Java Shell tool `opg-jshell`

执行下列命令，我们可以使用客户端 `opg-jshell` (Java Shell tool) 来连接进入 Graph 服务器。

```sh
opg-jshell --base_url https://localhost:7007 --username demograph
```

[Figure: jshell connect]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b647ebaf-8cc2-4a2e-8da1-875351a11468.png)

### Python client `opgpy`

除了 Java Shell tool `opgjshell`，我们还可以使用 Python 客户端 `opgpy`。在其中，我们可以使用 Python 语言与 Graph 服务进行交互。

```sh
opgpy --base_url https://localhost:7007 --user demograph
```

[Figure: Python client]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/7b3756e7-b1df-89f3-0803-19ddde9c44a1.png)

## Graph in PGX

在本节中，我们将使用 Python 客户端 `opgpy` 来连接进入 Graph 服务， 并与之进行交互操作。

### 创建 graph

执行下列命令可以基于我们之前在数据库中准备好的 Online Retail 相关的表来创建相应的 Graph。

```py
stmt_create = """
CREATE PROPERTY GRAPH "online_retail"
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
graph_online_retail = session.get_graph("online_retail")
graph_online_retail
```

[Figure: create graph online_retail]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/dcabf147-6992-c2c1-7cb8-bea2cf917c4b.png)

### 查询 graph

执行下面的命令来对我们创建好的 Graph 进行查询。

```py
graph_online_retail.query_pgql("SELECT ID(c), ID(p), p.description FROM online_retail MATCH (c)-[has_purchased]->(p) WHERE c.CUSTOMER_ID = 'cust_12353'").print();
```

[Figure: query graph online_retail]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/3c992fb6-906c-9e5b-0533-c8cbb4347444.png)

### 销毁 graph

下面命令可以销毁我们创建的 Graph。

```py
graph_online_retail.destroy()
session.get_graph("online_retail")
```

[Figure: destroy graph]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/a0711c4e-eb55-bca8-f3ec-2f01745b8528.png)


## 总结

通过本文，我们体验了如何从应用程序市场来部署 Oracle Property Graph 服务器。如您所见，我们只需要进行简单的点击，并输入很少的必要信息即可快速部署一台完善可用的 Graph 服务器。
