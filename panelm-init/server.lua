local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")

local version = module("panelm-init", "version")
PerformHttpRequest("https://raw.githubusercontent.com/stefandev15/panelm-init/master/version.lua",
  function(err, text)
    if err == 200 then
      local newestVersion = string.gsub(text, '^%s*return%s*"(.-)"%s*$', '%1')
      if (newestVersion == version) then
        print("^2You are running the lastest version of ^5panelm-init^7")
      else
        error("^6You are running version ^3" ..
          version ..
          " ^6of ^5panelm-init^6, newest version: ^3" ..
          newestVersion .. " \n^6Please update by vising ^3panelm.org^6! ^7")
      end
    else
      error("unable to check the panelm-init version^7")
    end
  end)

local tables = {
  ["vrp_users"] = { "id", "last_login", "username", "online", "discord" },
  ["vrp_user_moneys"] = { "user_id", "wallet", "bank" },
  ["vrp_user_vehicles"] = { "user_id", "vehicle" },
}

Citizen.CreateThread(function()
  Wait(1000)
  exports['ghmattimysql']:execute("ALTER TABLE vrp_users ADD IF NOT EXISTS username TEXT NOT NULL DEFAULT 'user';")
  exports['ghmattimysql']:execute("ALTER TABLE vrp_users ADD IF NOT EXISTS online TINYINT(1) NOT NULL DEFAULT 0;")
  exports['ghmattimysql']:execute("ALTER TABLE vrp_users ADD IF NOT EXISTS discord VARCHAR(32) NOT NULL DEFAULT '';")
  Wait(2.5 * 1000)
  for table in pairs(tables) do
    for _, column in pairs(tables[table]) do
      local query = string.format(
        "SELECT COUNT(*) AS count FROM information_schema.columns WHERE table_name = '" ..
        table .. "' AND column_name = '%s'", column)
      exports['ghmattimysql']:execute(query, function(rows)
        for _, count in pairs(rows[1]) do
          if count == 0 then
            error("Error: Missing column - " .. column .. " in " .. table .. "^7")
          end
        end
      end)
    end
  end
end)

AddEventHandler('vRP:playerSpawn', function(user_id, source, first_spawn)
  if first_spawn then
    local discord = ""
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
      local id = GetPlayerIdentifier(source, i)
      if string.find(id, "discord") then
        discord = string.sub(id, #"discord:" + 1)
      end
    end
    exports['ghmattimysql']:execute(
      "UPDATE vrp_users SET username = @username, online = 1, discord = @discord WHERE id = @id",
      { id = user_id, username = GetPlayerName(source), discord = discord })
  end
end)

AddEventHandler("playerDropped", function(reason)
  local source = source
  local user_id = vRP.getUserId({ source })
  exports['ghmattimysql']:execute("UPDATE vrp_users SET online = 0 WHERE id = @id",
    { id = user_id })
end)
