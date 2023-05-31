@echo off
setLocal



FOR /F "tokens=1* delims==" %%A IN (config.properties) DO (
    if "%%A"=="username" set TARGET_DB_USERNAME=%%B
    if "%%A"=="password" set TARGET_DB_PASSWORD=%%B
    if "%%A"=="referenceUsername" set REFERENCE_DB_USERNAME=%%B
    if "%%A"=="referencePassword" set REFERENCE_DB_PASSWORD=%%B
    if "%%A"=="liquibaseVersion" call :trim %%B TOOL_VERSION
    if "%%A"=="debug" call :trim %%B DEBUG
    if "%%A" == "url" (
                SET TARGET_DB_URL=%%B
                echo TARGET_DB_URL: %TARGET_DB_URL%
                FOR /F "tokens=1,2,3,4 delims=:"  %%G IN ("%TARGET_DB_URL%") DO (
                    echo %%G %%H %%I %%J
                    SET TARGET_DBTYPE=%%H
                    SET _t=%%I
                    SET TARGET_SERVER=%_t:~2%
                    set _b=%%J
                    FOR /F "tokens=1,2 delims=/" %%V IN ("%_b%") DO (
                        SET TARGET_SERVER_PORT=%%V
                        SET TARGET_SERVER_DB_NAME=%%W
                    )
                    echo ******* target server variables *********************
                    echo target db server: %TARGET_SERVER%
                    echo target db server port: %TARGET_SERVER_PORT%
                    echo target db server username: %TARGET_DB_USERNAME%  
                    echo target db server password: %TARGET_DB_PASSWORD%
                    echo target db name: %TARGET_SERVER_DB_NAME%
                )
            )  

    if "%%A"=="referenceUrl" (
                set REFERENCE_DB_URL=%%B
                FOR /F "tokens=1,2,3,4 delims=:" %%K IN ("%REFERENCE_DB_URL%") DO (
                echo %%K %%L %%M %%N
                SET REF_DBTYPE=%%L
                SET _r=%%M
                SET REF_SERVER=%_r:~2%
                set _b=%%N
                FOR /F "tokens=1,2 delims=/" %%X IN ("%_b%") DO (
                    SET REF_SERVER_PORT=%%X
                    SET REF_SERVER_DB_NAME=%%Y
                )
                echo ******* Reference server variables *********************
                echo reference db server: %REF_SERVER%
                echo reference db server port: %REF_SERVER_PORT%
                echo reference db username: %REFERENCE_DB_USERNAME%
                echo reference db password: %REFERENCE_DB_PASSWORD%
                echo reference db name: %REF_SERVER_DB_NAME%
            )
        )

    )
ECHO %TOOL_VERSIOn%
::if not "%~1" == "" SET TOOL_VERSION=%~1
Set PROJECT_BASE=%~dp0
Set VERSION=liquibase-v%TOOL_VERSION%
Set SERVICE_TOOL=%PROJECT_BASE%liquibase\%VERSION%\liquibase.bat
Set SERVICE_REPO=%PROJECT_BASE%liquibase\%VERSION%
Set CHANGE_LOG_DIR=%PROJECT_BASE%changelog\script
Set ROOT_CHANGE_LOG_DIR=%PROJECT_BASE%changelog
Set DEFAULT_CHANGE_LOG=%ROOT_CHANGE_LOG_DIR%\root.yaml
Set SEARCH_WORD="Liquibase Version"
call :main %*

:clear_env
    rem "clear all env variables"
    SET PROJECT_BASE=
    SET VERSION=
    SET SERVICE_TOOL=
    SET SERVICE_REPO=
    SET CHANGE_LOG_DIR=
    SET ROOT_CHANGE_LOG=
    SET ROOT_CHANGE_LOG_DIR=
    SET DEFAULT_CHANGE_LOG=
    SET REF_DBTYPE=
    SET DB_TYPE=
    SET REF_SERVER=
    SET REF_SERVER_PORT=
    SET REFERENCE_DB_URL=
    SET REFERENCE_DB_USERNAME= 
    SET REFERENCE_DB_PASSWORD=
    SET REF_SERVER_DB_NAME=
    SET TARGET_DB_URL=  
    SET TARGET_DB_USERNAME=  
    SET TARGET_DB_PASSWORD=
    SET TARGET_SERVER_PORT=
    SET TARGET_SERVER_DB_NAME=
    SET DEBUG=
    echo env variables cleared!
goto :eof

:usage
    echo Usage:  Liquibase-service (command) [OPTIONS]
    echo command:
    echo        -c                          Clear  Env variables
    echo        -e                          Show   Env variables
    echo        -s                          Switch Liquibase version
    echo        -r                          Reset  Liquibase version
    echo        -v                          Show   Liquibase version
    echo        init                        Init   Liquibase service
    echo        dump                        Start  Liquibase dump tool 
    echo        restore                     Start  Liquibase restore tool 
    echo        diff                        Create sql diff output from a reference database against target one.
    echo                                    The output sql can be used for check or update of the target database.
    echo OPTIONS:
    echo    dump: 
    echo         --all                      Dump schema, constraint and data from reference database 
    echo         --data                     Dump only data from reference database
    echo         --table                    Dump only schema from reference database
    echo         --constraint               Dump only constraint from reference database
    echo    restore: 
    echo         --all                      Restore schema, constraint and data from target database
    echo         --data                     Restore only data from target database
    echo         --table                    Restore only schema from target database
    echo         --constraint               Restore only constraint from target database
    echo    -s: 
    echo         3|4                        switch liquibase version to the selected version number

goto :eof

:trim
    set %2=%1
goto :eof

:extractDBType
    FOR /F "tokens=2 delims=:" %%X in ("%1") do (
        set DB_TYPE=%%X
    )
goto :eof

:dump_all_v3
    echo "calling Liquibase v3 for dump..." 
    if "%DB_TYPE%" == "" set DB_TYPE=postgresql
    if /I "%DEBUG%" == "true" echo "%SERVICE_TOOL%  generateChangeLog --changeLogFile="%CHANGE_LOG_DIR%\all.%DB_TYPE%.sql" --logLevel=severe --url="%2" --username=%3 --password=%4"
    call %SERVICE_TOOL%   --changeLogFile="%CHANGE_LOG_DIR%\all.%DB_TYPE%.sql" --diffTypes="tables, columns, indexes, foreignkeys, primarykeys, uniqueconstraints, data"  --logLevel=severe --url=%2 --username=%3 --password=%4  generateChangeLog && java -jar %PROJECT_BASE%\bin\splitter.jar %CHANGE_LOG_DIR%\all.%DB_TYPE%.sql
    if %ERRORLEVEL% EQU 0 (
        if "%1" == "--constraint" del %CHANGE_LOG_DIR%\data.%DB_TYPE%.sql %CHANGE_LOG_DIR%\schema.%DB_TYPE%.sql /f /q  
        if "%1" == "--schema"     del %CHANGE_LOG_DIR%\constraint.%DB_TYPE%.sql %CHANGE_LOG_DIR%\data.%DB_TYPE%.sql /f /q  
        if "%1" == "--data"       del %CHANGE_LOG_DIR%\schema.%DB_TYPE%.sql %CHANGE_LOG_DIR%\constraint.%DB_TYPE%.sql /f /q 
    )
    move %CHANGE_LOG_DIR%\all.%DB_TYPE%.sql  %CHANGE_LOG_DIR%\..\all.sql
goto :eof

:dump_all
    Echo "%TOOL_VERSION%"
    if /I "%DEBUG%" == "true" echo "dumping all (schema + constraint + data) from DB %REFERENCE_DB_URL%"
    if "%TOOL_VERSION%" == "4" (
        call :dump_table %1 %2 %3
        call :dump_constraint %1 %2 %3
        call :dump_data %1 %2 %3
    )
    if "%TOOL_VERSION%" == "3" (
        echo call of v3
        call :dump_all_v3 --all %1 %2 %3
    )
goto :eof

:dump_table
    if /I "%DEBUG%" == "true" echo "dumping schema from DB %REFERENCE_DB_URL%"
    if "%TOOL_VERSION%" == "3" call :dump_all_v3 --schema %1 %2 %3
    if "%TOOL_VERSION%" == "4" call  %SERVICE_TOOL%   --changeLogFile="%CHANGE_LOG_DIR%\schema.%DB_TYPE%.sql" --diffTypes="tables, columns" --logLevel=severe --url="%~1" --username=%~2 --password=%~3 generateChangeLog
goto :eof

:dump_constraint
    if /I "%DEBUG%" == "true" echo "dumping constraints from DB %REFERENCE_DB_URL%"
    if /I "%DEBUG%" == "true" echo "TOOL_VERSION : %TOOL_VERSION%"
    if "%TOOL_VERSION%" == "3" call :dump_all_v3 --constraint %~1 %~2 %~3
    if "%TOOL_VERSION%" == "4" call %SERVICE_TOOL%   --changeLogFile="%CHANGE_LOG_DIR%\constraint.%DB_TYPE%.sql" --diffTypes="indexes, foreignkeys, primarykeys, uniqueconstraints" --logLevel=severe --url="%~1" --username=%~2 --password=%~3 generateChangeLog
goto :eof

:dump_data
    if /I "%DEBUG%" == "true" echo "dumping data from DB %REFERENCE_DB_URL%"
    if "%TOOL_VERSION%" == "3" call :dump_all_v3 --data %1 %2 %3
    if "%TOOL_VERSION%" == "4" call %SERVICE_TOOL%   --changeLogFile="%CHANGE_LOG_DIR%\data.%DB_TYPE%.sql" --diffTypes="data" --logLevel="severe" --url="%~1" --username=%~2 --password=%~3  generateChangeLog
goto :eof

:dump
    del %CHANGE_LOG_DIR% /f /q
    if /I "%DEBUG%" == "true" echo "Dump action => target DB %REFERENCE_DB_URL%"
    if /I "%1" == ""                call :dump_all          "%REFERENCE_DB_URL%" "%REFERENCE_DB_USERNAME%" "%REFERENCE_DB_PASSWORD%"
    if /I "%1" == "--all"           call :dump_all          "%REFERENCE_DB_URL%" "%REFERENCE_DB_USERNAME%" "%REFERENCE_DB_PASSWORD%"
    if /I "%1" == "--data"          call :dump_data         "%REFERENCE_DB_URL%" "%REFERENCE_DB_USERNAME%" "%REFERENCE_DB_PASSWORD%"
    if /I "%1" == "--table"         call :dump_table        "%REFERENCE_DB_URL%" "%REFERENCE_DB_USERNAME%" "%REFERENCE_DB_PASSWORD%"
    if /I "%1" == "--constraint"    call :dump_constraint   "%REFERENCE_DB_URL%" "%REFERENCE_DB_USERNAME%" "%REFERENCE_DB_PASSWORD%"
goto :eof

:copyChangeLogFile
    if /I "%DEBUG%" == "true" ( echo "copying changelog files into %PROJECT_BASE%liquibase\%VERSION%\" )
    rmdir %PROJECT_BASE%liquibase\%VERSION%\script /s /q
    pause
    mkdir %PROJECT_BASE%liquibase\%VERSION%\script 1>nul 2>&1
    mkdir %PROJECT_BASE%liquibase\%VERSION%\script\table 1>nul 2>&1
    mkdir %PROJECT_BASE%liquibase\%VERSION%\script\constraint 1>nul 2>&1
    mkdir %PROJECT_BASE%liquibase\%VERSION%\script\data 1>nul 2>&1
    mkdir %PROJECT_BASE%liquibase\%VERSION%\script\sql  1>nul 2>&1
    if not "%~1" == "" (
         xcopy %1 %PROJECT_BASE%liquibase\%VERSION%\script\sql\ /Y /R /Q
    ) else (
        xcopy %CHANGE_LOG_DIR%\schema.%DB_TYPE%.sql %PROJECT_BASE%liquibase\%VERSION%\script\table\ /Y /R /Q
        xcopy %CHANGE_LOG_DIR%\constraint.%DB_TYPE%.sql %PROJECT_BASE%liquibase\%VERSION%\script\constraint\  /Y /R /Q
        xcopy %CHANGE_LOG_DIR%\data.%DB_TYPE%.sql %PROJECT_BASE%liquibase\%VERSION%\script\data\ /Y /R /Q
    )
goto :eof


:restore_all
    if /I "%DEBUG%" == "true" echo "Restore database from changelog => target DB %TARGET_DB_URL%"
    if "%TOOL_VERSION%" == "3" call %SERVICE_TOOL%  --classpath=%ROOT_CHANGE_LOG_DIR%  --changeLogFile="%ROOT_CHANGE_LOG_DIR%\root.yaml" --logLevel=severe  --url=%~1 --username=%~2 --password=%~3  update
    if "%TOOL_VERSION%" == "4" call %SERVICE_TOOL%  --searchPath=%ROOT_CHANGE_LOG_DIR%  --changeLogFile="root.yaml" --logLevel=severe  --url=%~1 --username=%~2 --password=%~3  update
goto :eof

:restore_table
    if /I "%DEBUG%" == "true" echo "Restore schema changelog only..."
    call :copyChangeLogFile %CHANGE_LOG_DIR%\schema.%DB_TYPE%.sql
    call %SERVICE_TOOL% --version
    ::call %SERVICE_TOOL%   --changeLogFile="root.yaml"  --logLevel=severe  --url=%~1 --username=%~2 --password=%~3  update
goto :eof

:restore_constraint
    if /I "%DEBUG%" == "true" echo "Restore constraint changelog only..."
    call :copyChangeLogFile %CHANGE_LOG_DIR%\constraint.%DB_TYPE%.sql
    call %SERVICE_TOOL% --version
    ::call %SERVICE_TOOL%  --changeLogFile="root.yaml"  --logLevel=severe  --url=%~1 --username=%~2 --password=%~3  update
goto :eof

:restore_data
    if /I "%DEBUG%" == "true" echo "Restore data changelog only..."
    call :copyChangeLogFile %CHANGE_LOG_DIR%\data.%DB_TYPE%.sql
    call %SERVICE_TOOL% --version
    ::call %SERVICE_TOOL%   --changeLogFile="root.yaml"  --logLevel=severe  --url=%~1 --username=%~2 --password=%~3  update
goto :eof

:restore
    echo "Restore action => target DB %~1"
    if "%~1" == ""                  call :restore_all           "%TARGET_DB_URL%" "%TARGET_DB_USERNAME%" "%TARGET_DB_PASSWORD%"
    if /I "%1" == "--all"           call :restore_all           "%TARGET_DB_URL%" "%TARGET_DB_USERNAME%" "%TARGET_DB_PASSWORD%"
    if /I "%1" == "--data"          call :restore_data          "%TARGET_DB_URL%" "%TARGET_DB_USERNAME%" "%TARGET_DB_PASSWORD%"
    if /I "%1" == "--table"         call :restore_table         "%TARGET_DB_URL%" "%TARGET_DB_USERNAME%" "%TARGET_DB_PASSWORD%"
    if /I "%1" == "--constraint"    call :restore_constraint    "%TARGET_DB_URL%" "%TARGET_DB_USERNAME%" "%TARGET_DB_PASSWORD%"
goto :eof

:showVersion
    call %SERVICE_TOOL% --version | findstr /B /C:%SEARCH_WORD%
goto :eof

:diffSchema
    if /I "%DEBUG%" == "true" echo "%SERVICE_TOOL% %SERVICE_TOOL%  --changeLogFile="%CHANGE_LOG_DIR%\diffSchema.postgresql.sql diffChangeLog --url="%TARGET_DB_URL%" --username=%TARGET_DB_USERNAME% --password=%TARGET_DB_PASSWORD% --referenceUrl="%REFERENCE_DB_URL%" --referenceUsername=%REFERENCE_DB_USERNAME% --referencePassword=%REFERENCE_DB_PASSWORD%"
    call %SERVICE_TOOL%  --changeLogFile="%CHANGE_LOG_DIR%\diffSchema.postgresql.sql diffChangeLog --url="%TARGET_DB_URL%" --username=%TARGET_DB_USERNAME% --password=%TARGET_DB_PASSWORD% --referenceUrl="%REFERENCE_DB_URL%" --referenceUsername=%REFERENCE_DB_USERNAME% --referencePassword=%REFERENCE_DB_PASSWORD%
goto :eof

:diff
    echo "executing diff changelog command..."
    call :diffSchema
goto :eof

:switch_version
    call :set_env %1
    call :showVersion
goto :eof

:init
    call :clear_env
    call :set_env
    call :show_env
    call :showVersion
goto :eof

:show_env
    rem  %env variables
    echo ******* Global variables *********************
    echo project base dir: %PROJECT_BASE%
    echo liquibase version: %VERSION%
    echo liquibase executable path: %SERVICE_TOOL%
    echo changelogs base dir: %CHANGE_LOG_DIR%
    echo root changelog base dir: %ROOT_CHANGE_LOG_DIR%
    echo debug mode: %DEBUG%

    echo ******* Reference server variables *********************
    echo reference db server: %REF_SERVER%
    echo reference db server port: %REF_SERVER_PORT%
    echo reference db username: %REFERENCE_DB_USERNAME%
    echo reference db password: %REFERENCE_DB_PASSWORD%
    echo reference db name: %REF_SERVER_DB_NAME%

    echo ******* target server variables *********************
    echo target db server: %TARGET_SERVER%
    echo target db server port: %TARGET_SERVER_PORT%
    echo target db server username: %TARGET_DB_USERNAME%  
    echo target db server password: %TARGET_DB_PASSWORD%
    echo target db name: %TARGET_SERVER_DB_NAME%
goto :eof

:test_dump_restore_postgresql_mixed_version
    call :switch_version 3
    call :dump
    call :switch_version 4
    call :restore
goto :eof

:test_dump_restore_postgresql_same_version
    call :dump
    call :restore
goto :eof

:extract_server
    SET REF_SERVER=%1:~2%
    echo %REF_SERVER%
goto :eof


:check_db
    echo "start checking database connection metadata ..."
    rem "%REFERENCE_DB_URL%" "%REFERENCE_DB_USERNAME%" "%REFERENCE_DB_PASSWORD%"
    echo "check of ref db.."
    if /I "%DEBUG%" == "true" echo "ref db..."
    echo "host=%REF_SERVER% port=%REF_SERVER_PORT% user=%REFERENCE_DB_USERNAME% password=%REFERENCE_DB_PASSWORD% dbname=%REF_SERVER_DB_NAME%  dbtype=%REF_DBTYPE%"
    if not "%REF_SERVER%" == "" (
        for /f "delims=" %%i in ('psql "host=%REF_SERVER% port=%REF_SERVER_PORT% user=%REFERENCE_DB_USERNAME% password=%REFERENCE_DB_PASSWORD% dbname=%REF_SERVER_DB_NAME%"') do 
            set now=%%i 
            echo %%i
        IF %ERRORLEVEL% NEQ 0 ( 
            call :err_db_check %REF_SERVER_DB_NAME% %REF_SERVER%
        )
    )


    rem "%TARGET_DB_URL%" "%TARGET_DB_USERNAME%" "%TARGET_DB_PASSWORD%"
    echo "check of target db.."
    if /I "%DEBUG%" == "true" echo "target db.."
    echo "host=%TARGET_SERVER% port=%TARGET_SERVER_PORT% user=%TARGET_DB_USERNAME% password=%TARGET_DB_PASSWORD% dbname=%TARGET_SERVER_DB_NAME%  dbtype=%TARGET_DBTYPE%"
    if not "%TARGET_SERVER%" == "" (
        for /f "delims=" %%i in ('dir') do 
        set now=%%i 
        echo %%i
        IF %ERRORLEVEL% NEQ 0 ( 
            call :err_db_check %TARGET_SERVER_DB_NAME% %TARGET_SERVER%
        )
    )
    
goto :eof

:err_db_check
    echo "FATAL: Database %1 not found on server %2%"
goto :eof

:main
    echo %*
    if /I "%~1" == "init"                                   call :init
    if /I "%~1" == "checkdb"                                call :check_db
    if /I "%~1" == "sync-mixed"                             call :test_dump_restore_postgresql_mixed_version
    if /I "%~1" == "sync-same"                              call :test_dump_restore_postgresql_same_version
    if /I "%~1" == "diff"                                   call :diff
    if /I "%~1" == "dump"                                   call :dump %2
    if /I "%~1" == "restore"                                call :restore %2
    if /I "%~1" == "-v"                                     call :showVersion
    if /I "%~1" == "-c"                                     call :clear_env
    if /I "%~1" == "-s"                                     call :switch_version %2
    if /I "%~1" == "-i"                                     call :init
    if /I "%~1" == "-e"                                     call :show_env
    if    "%~1" == ""                                       call :usage
goto :eof

endLocal