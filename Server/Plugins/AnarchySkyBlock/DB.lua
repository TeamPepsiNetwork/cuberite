-- helper methods for working with the SQLite db

DB = nil

function LoadDB()
    if (DB ~= nil) then
        LOGERROR("DB already open!")
        return false
    else
        DB = sqlite3.open(LOCAL_FOLDER .. "/database.sqlite3")
        TryExec("CREATE TABLE IF NOT EXISTS skyblock (uuid CHAR(32) NOT NULL, data JSON, PRIMARY KEY(uuid))")
        return true
    end
end

function CloseDB()
    if (DB ~= nil) then
        DB:close()
        DB = nil
        return true
    else
        LOGERROR("DB already closed!")
        return false
    end
end

function TryExec(query)
    if (DB:exec(query) ~= sqlite3.OK) then
        LOGERROR("Unable to execute query!")
        LOGERROR("Query:")
        LOGERROR(query)
        return false
    else
        return true
    end
end
