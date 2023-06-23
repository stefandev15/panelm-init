local Proxy = module('vrp', 'lib/Proxy')
vRP = Proxy.getInterface('vRP')

print("^5[VRP]: ^7" .. 'Checking for vRP Updates..')

PerformHttpRequest("https://raw.githubusercontent.com/DunkoUK/dunko_vrp/master/vrp/version.lua",
  function(err, text, headers)
    if err == 200 then
      text = string.gsub(text, "return ", "")
      local r_version = tonumber(text)
      if version ~= r_version then
        print("^5[VRP]: ^7" .. 'A Dunko Update is available from: https://github.com/DunkoUK/dunko_vrp')
      else
        print("^5[VRP]: ^7" ..
          'You are running the most up to date Dunko Version. Thanks for using Dunko_vRP and thanks to our contributors for updating the project. Support Found At: https://discord.gg/b8wQn2XqDt')
      end
    else
      print("[vRP] unable to check the remote version")
    end
  end, "GET", "")




local tables = {
  ["vrp_users"] = { "id", "last_login", "username", "online", "discord" },
  ["vrp_user_moneys"] = { "user_id", "wallet", "bank" },
  ["vrp_user_vehicles"] = { "user_id", "vehicle" },
}

for table in pairs(tables) do
  for _, column in pairs(tables[table]) do
    local query = string.format(
      "SELECT COUNT(*) AS count FROM information_schema.columns WHERE table_name = '" ..
      table .. "' AND column_name = '%s'", column)
    exports['ghmattimysql']:execute(query, function(rows, affected)
      for _, count in pairs(rows[1]) do
        if count == 0 then
          error("Error: Missing column - " .. column .. " in " .. table)
          MySQL.SingleQuery("ALTER TABLE " .. table .. " ADD IF NOT EXISTS " ..
            column .. " VARCHAT(255) NOT NULL DEFAULT '';")
          print("Created column - " .. column .. " in " .. table)
        end
      end
    end)
  end
end


AddEventHandler('vRP:playerSpawn', function(user_id, source, first_spawn)
  if (not first_spawn) then
    return
  end

  local discord
  for i = 0, GetNumPlayerIdentifiers(source) - 1 do
    local id = GetPlayerIdentifier(source, i)
    if string.find(id, "discord") then
      discord = id
    end
    print({ username, user_id, discord })
    exports['ghmattimysql']:execute(
      "UPDATE vrp_users SET username = @username, online = 1, discord = @discord WHERE user_id = @user_id",
      { user_id, username = GetPlayerName(source), discord })
  end
end)

AddEventHandler("playerDropped", function(reason)
  local source = source
  local user_id = vRP.getUserId(source)
  exports['ghmattimysql']:execute("UPDATE vrp_users SET online = 0 WHERE user_id = @user_id",
    { user_id })
end)
