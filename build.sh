test -d "bin/" && rm -rf "bin/"
mkdir -p "bin/" && cp -rf "src/." "bin/"
cd bin/
cp "/usr/local/share/lua/5.3/binser.lua" "./"
cp "/usr/local/share/lua/5.3/socket.lua" "./"
luastatic main.lua binser.lua socket.lua controllers/Server.lua models/business/NewsManager.lua models/business/ConsensusManager.lua models/business/ServersHistory.lua /usr/lib/x86_64-linux-gnu/liblua5.3.a -I/usr/include/lua5.3
chmod +x main

cp -rf "/usr/local/lib/lua/5.3/socket/" "socket/"
cp -rf "/usr/local/lib/lua/5.3/lfs.so" "./"
cp -rf "/usr/local/share/lua/5.3/socket/." "socket/"

tar -pcvzf release.v0.1.tar.gz "../bin/socket/" "../bin/main" "../bin/lfs.so" "../addresses.csv" "../config.conf" "../news.csv"
mv release.v0.1.tar.gz ../

