# Cartridge Tilt

You can either run main.lua with Lua or as an executable Bash script, like so:

```bash
# Run with Lua
$ lua main.lua [args]
```

```bash
# Run as a Bash script
$ chmod +x main.lua
$ ./main.lua [args]
```

The script accepts the following arguments:

```
-d, --directory		Set the directory to generate levels in
-s, --seed		Set the seed for the random level generator (defaults to "Cartridge Tilt")
--AE			Generate levels in Alesan's Entities format instead of 1.6 format
```
