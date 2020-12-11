# Deploy Oracle Property Graph Server from Marketplace

In the last post - [How to setup and start to use Oracle Property Graph server](https://qiita.com/RexZheng/items/4b75efd1149d67cf93bf), we talked about how to setup and start to use Oracle Graph Server and Client on a DBCS instance. But all the steps are completed manually, and the Graph Server and database instance reside in the same server (VM). From the best practice perspective, this is not a good approach. The property graph server and database instance should be deployed in separated servers to avoid interference to each other.

Furthermore, there should be an easier way to do the deployment. We are on the Cloud, don't we?

## Prerequisite

The Graph Server will be deployed in front of a DBCS instance, so an existing DBCS instance is expected and we need to do some configuration in the database.

For details, please refer to the [Configuration in Oracle Database](https://qiita.com/RexZheng/items/4b75efd1149d67cf93bf#configuration-in-oracle-database) section in last post.

### Configuration in Oracle Database

Switch user to `oracle` and connect to Oracle Database as `sys`.

```sh
sudo su - oracle
sqlplus / as sysdba
```

[Figure: connect to DB]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/f5cd3c63-eb09-839c-bb06-e667f50786fc.png)

- PL/SQL Packages

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

- user & roles

Create database user `demograph` in PDB `pdb1`, grant role and tablespace accordingly.
All the tables will be created and loaded into this schema `demograph`.

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

### Create Online Retail tables

Please refer to the [Create Online Retail tables](https://github.com/rexzj266/oracle-pgx-on-dbcs-quickstart/blob/master/manual-setup/pgx-manual-setup-dbcs.md) section in the last post to create sample tables.

## Deploy from Marketplace

Visit OCI Marketplace and input keyword `graph`, then we will see the tile of Oracle Property Graph Server & Client image.

[Figure: Marketplace]

![marketplace.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/2c5c52eb-7115-a06f-b036-a95b7beb2631.png)

[Figure: PGX in marketplace]

![PGX in marketplace](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/bbb9ffc7-8ae0-cc11-71be-189759c4a359.png)

Please read the `Overview` and `Usage Instructions` before you click the `Launch Stack` button.

[Figure: Launch Stack]

![Launch Stack](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/8f02d3e3-1754-82b0-4db7-6ed5e8541964.png)

Input a name of the stack. The compartment is selected same as the one when you launch the stack.

[Figure: Stack info 1]

![Stack info 1](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/622120a0-f16f-50c7-d09a-1cd976f5b859.png)

On the next page, we need to input more information.

In the Oracle Graph Server Compute Instance section,

- `RESOURCE NAME PREFIX` will help us to identify the created resources.
- `ORACLE GRAPH SERVER COMPARTMENT` allows us to choose which compartment to deploy the graph server.
- `ORACLE GRAPH SERVER SHAPE` allows us to choose different shape of the server. That means different performance of the server. Check [VM Shape page](https://docs.cloud.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm#vmshapes) to get more information of the shapes.
- `SSH PUBLIC KEY` is the key to connect to the compute instance in which the graph server is deployed.

[Figure: Stack info 2-1]

![Stack info 2-1](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/fbbea98d-d123-343b-4a5d-e373b991977d.png)

Scroll down the page, in the Instance Network section, we need to select compartment, VCN, subnet accordingly.

In the Graph Server Configuration section, `JDBC URL FOR AUTHENTICATION` is the JDBC connection string to the Oracle database we prepared in advance. Make sure the URL is accessible from the graph server. `PGQL ENGINE FOR GRAPHVIZ` we leave it as default.

[Figure: Stack info 2-2]

![Stack info 2-2](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/04327789-b700-ca95-a65a-27429acd8605.png)

Click Next and have brief review of our settings, then just click `Create` to start the deployment.

[Figure: Stack review]

![Stack review](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/572c53ac-1cad-8829-d771-d5cddcaa933e.png)

The deployment from marketplace image is performed by OCI Resource Manager. A job will be executed based on the information we configured just now.

[Figure: RM job]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/16fe3c47-ef88-b1a0-a8d7-3bab86af81ae.png)

Several minutes later, the resource manager job will be completed. We can visit the compute instance console to check the created graph server.

[Figure: Graph server compute instance]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/413e0c9c-4d3b-0820-7284-27c14db7ea83.png)

## Verify the deployment

### PGX service

As we can see on the compute instance console, the graph server (PGX20201127) is running. Now, we can use our favorite terminal to connect to the server and check the PGX service status.

```sh
systemctl status pgx
```

[Figure: PGX service status]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/e4adc419-07a1-1bd2-4b6e-2425c4802394.png)

### Java Shell tool `opg-jshell`

Let's perform following command to connect to the server.

```sh
opg-jshell --base_url https://localhost:7007 --username demograph
```

[Figure: jshell connect]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/b647ebaf-8cc2-4a2e-8da1-875351a11468.png)

### Python client `opgpy`

Besides the Java Shell tool `opgjshell`, Oracle also provides a Python client called `opgpy`. If you prefer Python syntax, you can try this one.

```sh
opgpy --base_url https://localhost:7007 --user demograph
```

[Figure: Python client]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/7b3756e7-b1df-89f3-0803-19ddde9c44a1.png)

## Graph in PGX

In this section, we will use the Python client `opgpy` to connect to the property graph server and interact with the database.

### Create graph

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

### Query graph

```py
graph_online_retail.query_pgql("SELECT ID(c), ID(p), p.description FROM online_retail MATCH (c)-[has_purchased]->(p) WHERE c.CUSTOMER_ID = 'cust_12353'").print();
```

[Figure: query graph online_retail]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/3c992fb6-906c-9e5b-0533-c8cbb4347444.png)

### Destroy graph

```py
graph_online_retail.destroy()
session.get_graph("online_retail")
```

[Figure: destroy graph]

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/100411/a0711c4e-eb55-bca8-f3ec-2f01745b8528.png)


## Conclusion

As we can see, by using the marketplace image, we just need to input some basic information and click some buttons, then we will get a fully workable Property Graph Server. If we have prepared properly, it may only cost us less than 5 minutes to make it done. Super easy! Isn't it?
