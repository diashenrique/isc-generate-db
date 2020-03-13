Class diashenrique.Utils.GenerateDB
{

Parameter LIBRARY = {$Select($Select($ZVersion["IRIS":1,1:0):"IRISLIB",1:"CACHELIB")};

Parameter SYSGLOBALS = {$Select($Select($ZVersion["IRIS":1,1:0):"IRISSYS",1:"CACHESYS")};

Parameter TEMPGLOBALS = {$Select($Select($ZVersion["IRIS":1,1:0):"IRISTEMP",1:"CACHETEMP")};

Parameter DATABASENAME = {$Select($Select($ZVersion["IRIS":1,1:0):"IRIS.DAT",1:"CACHE.DAT")};

ClassMethod CreateNew()
{
    Write !!

    Read "Do you want to create a new Database/Namespace? (Y/N) : ",tStart,!!

    If $Extract($ZConvert(tStart,"U"),1,1) = "Y" {
        Read "Choose your Namespace name : ",tNamespaceName,!
        Read "Choose the Dataset location <Path Default is mgr directory> : ",tPathDataset, !
        Read "Make this an Interoperability namespace? (Y/N) : ",tInteroperability,!
        Read "Do you want to split the database into CODE/DATA? (Y/N) : ",tCodeData,! 
        Read "Create a REST Application? (Y/N) : ",tREST,!

        Write !!

        Write "=======================================",!
        Write "=               SUMMARY               =",!
        Write "======================================="
        Write !!

        Write "Namespace => "_$ZConvert(tNamespaceName,"U"),!
        If $Extract($ZConvert(tCodeData,"U"),1,1) = "Y" {
            Set tCodeData = $$$YES
            Write "Database => "_$ZConvert(tNamespaceName,"U")_"-CODE / "_$ZConvert(tNamespaceName,"U")_"-DATA",!
        }
        Else {
            Set tCodeData = $$$NO
            Write "Database => "_$ZConvert(tNamespaceName,"U"),!
        }

        If (tPathDataset '= "") {
            Write "Dataset Location => "_$ZConvert(tPathDataset,"L"),!
        }
        Else {
            Write "Dataset Default Location => "_$System.Util.ManagerDirectory(),!
        }

        If $Extract($ZConvert(tInteroperability,"U"),1,1) = "Y" {
            Set tInteroperability = $$$YES
            Write "Interoperability => Yes",!
        }
        Else {
            Set tInteroperability = $$$NO
            Write "Interoperability => No",!
        }

        Write "CSP Application => /csp/"_$ZConvert(tNamespaceName,"L"),!
        If $Extract($ZConvert(tREST,"U"),1,1) = "Y" {
            Set tREST = $$$YES
            Write "REST Application => /rest/"_$ZConvert(tNamespaceName,"L"),!	
        }
        Else {
            Set tREST = $$$NO
            Write "REST Application => No",!
        }

        Write !!
        Read "Do you want to proceed? (Y/N) : ",tProceed,!

        If $Extract($ZConvert(tProceed,"U"),1,1) = "Y" {
            Do ..Install(tNamespaceName, tCodeData, tPathDataset, tInteroperability, tREST)
        }
        Else {
            Write #,!
            Do ..CreateNew()
        }

    }

    Quit
}

ClassMethod Install(pNamespace As %String, pCodeData As %Boolean, pPathDataset As %String, pInterOperability As %Boolean, pREST As %Boolean) As %Status
{
    Set sc = $$$OK
    Try {
        Set sc = $$$ADDSC(sc,..CreateDatabase(pNamespace, pCodeData, pPathDataset)) quit:$$$ISERR(sc)
        Set sc = $$$ADDSC(sc,..CreateNamespace(pNamespace, pCodeData, pInterOperability, pREST)) quit:$$$ISERR(sc)
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create new database directory
ClassMethod CreateDatabase(pNamespace As %String, pCodeData As %Boolean, pPathDataset As %String) As %Status [ Private ]
{
    New $Namespace
    Set $Namespace = "%SYS"
    Set sc = $$$OK
    Try {
        Set dbList = $Listbuild("")
        Set:(pCodeData = $$$YES) dbList= $Listbuild("-CODE","-DATA") 
        Set i = 0
        For i = 1:1:$Listlength(dbList) {
            Set dbSuffix = $Listget(dbList,i)
            If (pPathDataset '= "") {
                Set directory = pPathDataset_$Case($$$isWINDOWS,1:"\",:"/")_pNamespace_dbSuffix
            }
            Else {
                Set directory = ..GetDatabaseDirectory(pNamespace_dbSuffix)
            }

            #; create a new directory if does not exist
            If '..CheckDatabaseDirExists(directory) {
                Set directory = $ZStrip(directory,"<>W")
                Set sc = $$$ADDSC(sc,##class(%File).CreateDirectoryChain(directory))
                If $$$ISERR(sc) {
                    Set msg = directory_": Could not create this directory. Please check the directory and try again."
                    Set sc = $$$ADDSC(sc,$$$ERROR($$$GeneralError,msg))				
                }
            }
            Else {
                #; abort if database is already created
                If ..CheckDatabaseExists(directory) {
                    Set msg = directory_": Database already existent in this directory. Please check the directory and try again."
                    Set sc = $$$ADDSC(sc,$$$ERROR($$$GeneralError,msg))
                }
            }
            Quit:$$$ISERR(sc)

            #; create new database
            Set dbName = pNamespace_dbSuffix
            Write "Creating Database "_dbName_"... "
            Set size = 1
            Set blockSize = 8192
            Set properties("Directory") = directory
            Set journalState = 1
            Set sc = $$$ADDSC(sc,##class(SYS.Database).CreateDatabase(directory,size,blockSize,0,"%DB_DEFAULT",journalState,"",""))
            Quit:$$$ISERR(sc)

            #; Handle if we have dismounted then deleted the database at the O/S level,
            #; but the CPF entry still exists with the same directory, then recreate the DB only
            If ##class(Config.Databases).Exists(dbName,.obj) {
                If obj.Directory '= ##class(%File).ComputeFullDBDir(directory) {
                    Set sc = $$$ADDSC(sc,##Class(Config.Databases).Create(dbName,.properties))
                    Quit:$$$ISERR(sc)
                }
            }
            Else {
                Set sc = $$$ADDSC(sc,##Class(Config.Databases).Create(dbName,.properties))
                Quit:$$$ISERR(sc)
            }
            Write "done!",!
        }
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create new namespace
ClassMethod CreateNamespace(pNamespace As %String, pCodeData As %Boolean, pInterOperability As %Boolean, pREST As %Boolean) As %Status [ Private ]
{

    New $Namespace
    Set $Namespace = "%SYS"

    If (pCodeData = $$$YES) {
        Set strGlobals = pNamespace_"-DATA"
        Set strRoutine = pNamespace_"-CODE"
    }
    Else {
        Set (strGlobals, strRoutine) = pNamespace
    }

    Set sc = $$$OK
    Try {

        Write "Creating Namespace "_pNamespace_"... "

        Set nsProperties("Globals") = strGlobals
        Set nsProperties("Library") = ..#LIBRARY
        Set nsProperties("Routines") = strRoutine
        Set nsProperties("SysGlobals") = ..#SYSGLOBALS
        Set nsProperties("SysRoutines") = ..#SYSGLOBALS
        Set nsProperties("TempGlobals") = ..#TEMPGLOBALS
        Set sc = $$$ADDSC(sc,##Class(Config.Namespaces).Create(pNamespace,.nsProperties))

        Write "done!",!

        #; enable Interoperability
        If (pInterOperability = $$$YES) {
            Write "Creating Interoperability mappings ... "
            #; create InterOperability mappings
            Set:'$Data(^%SYS("Ensemble","InstalledNamespace",pNamespace)) ^%SYS("Ensemble","InstalledNamespace",pNamespace)=""
            Set sc = $$$ADDSC(sc,##class(%EnsembleMgr).createMappings(pNamespace))
            Write "done!",!

            Write "Adding Interoperability SQL privileges ... "
            #; add InterOperability SQL privileges
            Set sc = $$$ADDSC(sc,##class(%EnsembleMgr).addEnsembleSQLPrivileges(pNamespace))	
            Write "done!",!
        }
        Set sc = $$$ADDSC(sc,..CreateCSPApplication(pNamespace))
        If (pREST = $$$YES) {
            Set sc = $$$ADDSC(sc,..createRESTApp(pNamespace))
        }
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create CSP application
ClassMethod CreateCSPApplication(pNamespace As %String) As %Status [ Private ]
{
    Set sc = $$$OK
    New $Namespace
    Set $Namespace="%SYS"
    Try {
        Write "Creating CSP Application ... "
        Set lower = $ZConvert(pNamespace,"L")
        Set del = $Case($$$isWINDOWS,1:"\",:"/")
        Set cspName = "/csp/"_lower

        Set properties("Name") = cspName
        Set properties("CookiePath") = "/csp/"_lower
        Set properties("AutheEnabled") = $$$AutheUnauthenticated
        Set properties("NameSpace") = pNamespace
        Set properties("Path") = $System.Util.InstallDirectory()_"csp"_del_lower
        Set properties("GroupById") = $$$IscMgtPortalId
        Set properties("AutoCompile") = 1

        // If the application exists, quit
        If '##class(Security.Applications).Exists(cspName,.existingApp,.sc2) {
            // Create the csp application properties	
            Set sc = $$$ADDSC(sc,##class(Security.Applications).Create(cspName,.properties))
        }
        Else {
            Set sc = $$$ADDSC(sc,sc2)
        }
        Write "done!",!
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create REST Application
ClassMethod createRESTApp(pNamespace As %String) As %Status
{
    #dim sc As %Status = $$$OK

    New $Namespace
    Set $Namespace = "%SYS"

    Write "Creating CSP Application ... "

    Set lower = $ZConvert(pNamespace,"L")
    Set restName = "/rest/"_lower

    If '##class(Security.Applications).Exists(restName) {
        Set props("AutheEnabled") = $$$AutheUnauthenticated
        Set props("NameSpace") = pNamespace
        Set props("IsNameSpaceDefault") = $$$NO
        Set props("DispatchClass") = "REST.Dispatch"
        Set props("MatchRoles")=":%All"
        Set sc = ##class(Security.Applications).Create(restName, .props)
        Write "done!",!


        Write "Creating REST.Dispatch.cls ... "
        Do ..CreateDispatchClass(pNamespace)
        Write "done!",!
    }

    Quit sc
}

/// Create a dummy REST service to populate messages
ClassMethod CreateDispatchClass(pNamespace As %String) As %Status [ Private ]
{
    New $Namespace
    Set $Namespace = pNamespace
    Set sc = $$$OK
    Try {
        Set classname = "REST.Dispatch"
        Set class = ##class(%Dictionary.ClassDefinition).%New(classname)
        Set class.GeneratedBy = $ClassName()
        Set class.Super = "%CSP.REST"

        Set xdata = ##class(%Dictionary.XDataDefinition).%New()
        Set xdata.Name = "UrlMap"
        Set xdata.XMLNamespace = "http://www.intersystems.com/urlmap"
        Do xdata.Data.WriteLine("<Routes>")
        Do xdata.Data.WriteLine("<Route Url=""/"" Method=""GET"" Call=""Test"" Cors=""true""/>")
        Do xdata.Data.WriteLine("</Routes>")
        Do class.XDatas.Insert(xdata)
        Set sc = $$$ADDSC(sc,class.%Save())

        Set method = ##class(%Dictionary.MethodDefinition).%New(classname)
        Set method.Name = "Test"
        Set method.ClassMethod = 1
        Set method.ReturnType = "%Status"
        Set stream = ##class(%Stream.TmpCharacter).%New()
        Do stream.WriteLine("	Set %response.ContentType = ""application/json"" ")
        Do stream.WriteLine("	Set retObj = {}")
        Do stream.WriteLine("	Set retMessage = ""Hello World!"" ")
        Do stream.WriteLine("	Set retObj.Message = retMessage")
        Do stream.WriteLine("	Write retObj.%ToJSON()")
        Do stream.WriteLine("	Quit $$$OK")
        Set method.Implementation = stream
        Set sc = $$$ADDSC(sc,method.%Save())

        Set sc = $$$ADDSC(sc,$System.OBJ.Compile(classname,"fck-dv"))
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Get database directory
ClassMethod GetDatabaseDirectory(pNamespace As %String) As %String [ CodeMode = expression ]
{
##class(%File).SubDirectoryName($System.Util.ManagerDirectory(),$ZConvert(pNamespace,"L"))
}

/// Checks if database directory exist
ClassMethod CheckDatabaseDirExists(directory As %String) As %Status [ CodeMode = expression ]
{
##class(%File).DirectoryExists(directory)
}

/// Checks if database directory exist
ClassMethod CheckDatabaseExists(directory As %String) As %Status [ CodeMode = expression ]
{
##class(%File).Exists(directory_$Case($$$isWINDOWS,1:"\",:"/")_..#DATABASENAME)
}

}
