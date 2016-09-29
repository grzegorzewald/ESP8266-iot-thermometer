enduser_setup.start(
  function()
    print("Connected to wifi as: " .. wifi.sta.getip())
    tmr.alarm(0, 5000, 0, function()
        dofile("thermometer.lua")
    end)
  end
  ,
  function(err, str)
    print("enduser_setup: Err #" .. err .. ": " .. str)
  end
);