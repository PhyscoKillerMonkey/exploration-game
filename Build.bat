del Build /F /Q
md Build
copy /b "C:\Program Files\LOVE\love.exe"+%1 "%~n1.exe"
move Game.exe Build
cd Build
copy "C:\Program Files\LOVE\license.txt"
copy "C:\Program Files\LOVE\love.dll"
copy "C:\Program Files\LOVE\lua51.dll"
copy "C:\Program Files\LOVE\mpg123.dll"
copy "C:\Program Files\LOVE\msvcp120.dll"
copy "C:\Program Files\LOVE\msvcr120.dll"
copy "C:\Program Files\LOVE\OpenAL32.dll"
copy "C:\Program Files\LOVE\SDL2.dll"