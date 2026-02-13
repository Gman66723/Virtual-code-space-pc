#!/bin/bash
set -e # Exit on error

echo "--- 1. CLEANUP ---"
pkill -f vncserver || true
pkill -f websockify || true
rm -rf /tmp/.X11-unix /tmp/.X1-lock ~/.vnc/*.log ~/.vnc/*.pid || true

echo "--- 2. SETUP STARTUP SCRIPT ---"
mkdir -p ~/.vnc

# HERE IS THE FIX: 
# We start xterm in the background (&), but we run fluxbox in the foreground (exec)
# This prevents the script from exiting "too early".
cat <<EOF > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start a terminal so you have something to click on
xterm -geometry 80x24+10+10 -ls -title "Codespace Terminal" &

# Start the Window Manager and KEEP RUNNING
exec fluxbox
EOF

chmod +x ~/.vnc/xstartup

# Set a dummy password (needed by TigerVNC)
echo "password" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

echo "--- 3. START VNC SERVER ---"
# We use -localhost no to ensure the port isn't blocked internally
vncserver :1 -geometry 1280x720 -depth 24 -localhost no

echo "--- 4. VERIFY ---"
sleep 2
if pgrep -x "Xtigervnc" > /dev/null; then
    echo "✅ VNC IS RUNNING!"
else
    echo "❌ IT DIED AGAIN. LOGS:"
    cat ~/.vnc/*.log
    exit 1
fi

echo "--- 5. START WEB BRIDGE ---"
echo "👉 Go to PORTS -> 6080 -> Globe -> vnc.html -> Connect"
websockify --web=/usr/share/novnc/ 6080 localhost:5901