internalLed = 4
dhtData = 2

gpio.mode(internalLed, gpio.OUTPUT)
gpio.write(internalLed, gpio.HIGH)

function blinkLED(ms)
    gpio.write(internalLed, gpio.LOW)
    tmr.alarm(5, ms, 0, function()
        gpio.write(internalLed, gpio.HIGH)
    end)
end

function readDHT()
    status, temp, humi, temp_decimial, humi_decimial = dht.read(dhtData)
    sensorData.temperature = string.format("%d.%02d", math.floor(temp), temp_decimial)
    sensorData.humidity = string.format("%d.%02d", math.floor(humi), humi_decimial)
end

sensorData = {temperature = nil, humidity = nil}



tmr.alarm(6, 30000, 1, readDHT)

readDHT()
srv=net.createServer(net.TCP)
tmr.alarm(0, 10000, 0, function()
    srv:listen(80, function(conn)
        conn:on("receive", function(conn, payload)
            blinkLED(200)
            local peer_ip
            local r = {method = nil, uri = nil}
            for line in payload:gmatch("[^\r\n]+") do
                local _, len, method, uri = line:find("^([A-Z]+) (.-) HTTP/[1-9]+.[0-9]+$")
                if (len) then
                    r.method = method
                    r.uri = uri
                end
            end
            peer_ip = conn:getpeer()
            print("New connection from: " .. peer_ip .. " (" .. r.method .. ")")
            local response = "HTTP/1.1 "
            if (r.method == "GET") and (r.uri == "/") then
                response = response .. "200 OK\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n"
                response = response .. "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\">"
                response = response .. "<meta http-equiv=\"refresh\" content=\"60\">"
                response = response .. "<title>GForces Thermometer</title>"
                response = response .. "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">"
                response = response .. "</head>"
                response = response .. "<body><div class=\"container\">"
                response = response .. "<h1>Hello, GForces<br><small>are you cold or something?</small></h1>"
                response = response .. string.format("<h2><small>Temperature:</small> %s&deg;C</h2>", sensorData.temperature)
                response = response .. string.format("<h2><small>Humidity:</small> %s%%</h2>", sensorData.humidity)
                response = response .. "</div></body></html>"
            elseif (r.method == "GET") and (r.uri == "/api") then
                response = response .. "200 OK\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
                response = response .. cjson.encode(sensorData)
            else
                response = response .. "404 Not Found\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n"
                response = response .. "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\">"
                response = response .. "<title>404. This is very bad error</title>"
                response = response .. "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">"
                response = response .. "</head>"
                response = response .. "<body><div class=\"container\">"
                response = response .. "<h1>Naaat<br><small>Not found</small></h1>"
                response = response .. "</div></body></html>"
            end
            conn:send(response, function(sk)
                sk:close()
            end)
        end) 
    end)
    print("HTTP server started...")
    tmr.alarm(0, 15000, 0, function()
        mdns.register("termometr", { description="Network Thermometer", service="http", port=80, location="Grzegorz's Desk"})
        print("mDNS service started...")
    end)
end)
