## objectscript-contest-template
This is a template for InterSystems IRIS, Docker and ObjectScript Online contest. 
[Topic and Terms](https://community.intersystems.com/post/join-online-programming-contest-intersystems-iris-docker-and-objectscript)

## Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation 

Open terminal and clone/git pull the repo into any local directory

```
$ git clone git@github.com:intersystems-community/objectscript-contest-template.git
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
IRISAPP>do ##class(Contest.ObjectScript).TheUniverseQuestion()
42
```
## How to start coding
This repository is ready to code in VSCode with ObjectScript plugin.
Install [VSCode](https://code.visualstudio.com/), [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) and [ObjectScript](https://marketplace.visualstudio.com/items?itemName=daimor.vscode-objectscript) plugins and open the folder in VSCode.

Right-click on **docker-compose.yml** file and click Compose Restart

Once docker will finish starting procedure and show:

```
Creating objectscript-contest-template_iris_1 ... done
```

Click on the ObjectScript status bar and select Refresh connection in the menu.
Wait for VSCode to make connection and show something like "localhost:32778[IRISAPP] - Connected"

You can start coding after that. Open **ObjectScript.cls** in VSCode, make changes and save - the class will be compiled by IRIS on 'Save'.

## Happy coding!
