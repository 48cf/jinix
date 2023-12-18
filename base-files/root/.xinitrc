# ~/.xinitrc

feh --bg-fill ~/wallpaper.jpeg &
tint2 &
xterm -ls &

exec dbus-launch --exit-with-session xfwm4
# exec dbus-launch --exit-with-session xfce4-session
