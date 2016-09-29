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
    temperature = string.format("%d.%02d", math.floor(temp), temp_decimial)
    humidity = string.format("%d.%02d", math.floor(humi), humi_decimial)
end

temperature = 0.0
humidity = 0.0

tmr.alarm(6, 30000, 1, readDHT)

readDHT()
srv=net.createServer(net.TCP)
tmr.alarm(0, 10000, 0, function()
    print("HTTP server started...")
    srv:listen(80, function(conn)
        conn:on("receive", function(conn, payload)
            local response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n"
            local peer_ip
            peer_ip = conn:getpeer()
            print("New connection from: " .. peer_ip)
            blinkLED(200)
            response = response .. "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\">"
            response = response .. "<meta http-equiv=\"refresh\" content=\"60\">"
            response = response .. "<title>GForces Thermometer</title>"
            response = response .. "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">"
            response = response .. "</head>"
            response = response .. "<body><div class=\"container\">"
            response = response .. "<h1>Hello, GForces<br><small>are you cold or something?</small></h1>"
            response = response .. string.format("<h2><small>Temperature:</small> %s&deg;C</h2>", temperature)
            response = response .. string.format("<h2><small>Humidity:</small> %s%%</h2>", humidity)
            response = response .. "</div></body></html>"
            conn:send(response, function(sk)
                sk:close()
            end)
        end) 
    end)
    tmr.alarm(0, 5000, 0, function()
        mdns.register("termometr", { description="Network Termometer", service="http", port=80, location="Grzegorz's Desk"})
    end)
end)