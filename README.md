## Generate Database
Creating a new database, namespace, CSP/REST Application never been so easy.  

## Installation 

Open terminal and clone/git pull the repo into any local directory

```
$ git clone git@github.com:diashenrique/isc-generate-db.git
```

Open the terminal in this directory and run:

```
$ docker-compose build
```

3. Run the IRIS container with your project:

```
$ docker-compose up -d
```

## How to Run the Application

Open InterSystems IRIS terminal:

```
$ docker-compose exec iris iris session iris
USER>zn "IRISAPP"
IRISAPP>do ##class(diashenrique.Utils.GenerateDB).CreateNew()
```
## Options
You can choose the following options during the database creation:
* Namespace Name
* Dataset location (If empty, the ClassMethod uses the MGR directory)
* Make this an Interoperability Namespace
* If your dataset should be split into CODE and DATA or keep a single dataset for both
* If a REST Application should be created
  * Answering Y (Yes), a REST Application is created and also a Dispatch class.

## Example

```
$ docker-compose exec iris iris session iris


Do you want to create a new Database/Namespace? (Y/N) : Y

Choose your Namespace name : APPCNT
Choose the Dataset location <Path Default is mgr directory> : /opt/irisapp
Make this an Interoperability namespace? (Y/N) : Y
Do you want to split the database into CODE/DATA? (Y/N) : Y
Create a REST Application? (Y/N) : Y


=======================================
=               SUMMARY               =
=======================================

Namespace => APPCNT
Database => APPCNT-CODE / APPCNT-DATA
Dataset Location => /opt/irisapp
Interoperability => Yes
CSP Application => /csp/appcnt
REST Application => /rest/appcnt


Do you want to proceed? (Y/N) : Y
Creating Database APPCNT-CODE... done!
Creating Database APPCNT-DATA... done!
Creating Namespace APPCNT... done!
Creating InterOperability mappings ... done!
Adding InterOperability SQL privileges ... done!
Creating CSP Application ... done!
Creating CSP Application ... done!
Creating REST.Dispatch.cls ... done!
```
