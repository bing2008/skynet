cl /MD /O2 /c /DLUA_BUILD_AS_DLL *.c
ren lua.obj lua.o
ren luac.obj luac.o
link /DLL /IMPLIB:lua54.lib /OUT:lua54.dll /Machine:x64 *.obj
link /OUT:lua.exe /Machine:x64 lua.o lua54.lib
lib /OUT:lua-static.lib *.obj
link /OUT:luac.exe /Machine:x64 luac.o lua-static.lib