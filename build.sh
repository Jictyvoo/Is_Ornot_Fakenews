test -d "bin/" || mkdir -p "bin/" && cp -rf "src/." "bin/"
cd bin/
luastatic main.lua controllers/Server.lua models/business/NewsManager.lua models/business/ConsensusManager.lua models/business/ServersHistory.lua /usr/lib/x86_64-linux-gnu/liblua5.3.a -I/usr/include/lua5.3
chmod +x main
