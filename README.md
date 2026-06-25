# mspain`t
> [!IMPORTANT]
> I am NOT affiliated with mspaint (hence why i am mspain`t)

A decent script hub that *was* free and open source, and now being modifed by me, in progress

in the meantime, checkout the actual updated mspaint:
**Links**:
- [🌐 Website](https://www.mspaint.cc/)
- [💬 Discord](https://discord.gg/mspaint)




## Bundling mspain`t via wax
To bundle all the scripts, you have to follow these steps:

1. Install [rokit](https://github.com/rojo-rbx/rokit) if you haven't already
2. Open Powershell or the command-line shell of your liking and [cd to this repository](https://www.quora.com/What-does-it-mean-to-CD-into-a-directory-and-how-can-I-do-that-Can-someone-explain-it-in-a-laymans-term)
3. Run `rokit install` and wait for it to install all the dependencies
4. Run `lune run Build bundle input='default.project.json' minify=false output='Distribution/Script.luau' env-name="Script" darklua-config-path="Build/DarkLua.json" temp-dir-base="Distribution" verbose=true`

You can find the bundled script in `/Distribution/Script.luau`.
