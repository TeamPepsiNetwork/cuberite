-- helper methods for working with the SQLite db

DB = nil

function LoadDB()
    assert(DB == nil, "DB already open!")
    DB = sqlite3.open(LOCAL_FOLDER .. "/database.sqlite3")
    TryExec("CREATE TABLE IF NOT EXISTS skyblock (uuid CHAR(32) NOT NULL, data JSON, PRIMARY KEY(uuid))")
end

function CloseDB()
    assert(DB ~= nil, "DB already closed!")
    DB:close()
    DB = nil
end

function TryExec(query)
    assert(DB:exec(query) == sqlite3.OK, "Unable to execute query: \"" .. query .. "\"!")
end
