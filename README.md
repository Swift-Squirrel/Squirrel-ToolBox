[![CircleCI](https://img.shields.io/circleci/project/github/RedSparr0w/node-csgo-parser.svg)](https://circleci.com/gh/Swift-Squirrel/Squirrel-ToolBox)
[![platform](https://img.shields.io/badge/Platforms-OS_X%20%7C_Linux-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![SPM](https://img.shields.io/badge/spm-Compatible-brightgreen.svg)](https://swift.org)
[![swift](https://img.shields.io/badge/swift-4.0-orange.svg)](https://developer.apple.com/swift/)

# Squirrel-ToolBox

Toolbox for Swift Squirrel web framework (see: [Swift Squirrel](https://github.com/Swift-Squirrel/Squirrel))

### Installing

You can install toolbox to */usr/local/bin* with `install.sh`. If you want to install it in another directory just move executable to that directory or follow steps in [Custom installation](#custom-directory-installation). Also check `install.sh -h` for help

#### Installation script

For installation clone repositiory, cd to it and run `install.sh`. Make sure you have write permissions to */usr/local/bin*

```sh
git clone https://github.com/Swift-Squirrel/Squirrel-ToolBox.git
cd Squirrel-ToolBox
make install
./install

```

This will copy result binary to */usr/local/bin* and name it **squirrel**. After successful installation you can run `squirrel help` to show help

```sh
squirrel help # show help

```

#### Custom directory installation

This install toolbox to directory specified in `SQUIRREL_DIR` and set executable name to `SQUIRREL_NAME`

```sh
SQUIRREL_DIR="Your specific directory" 
SQUIRREL_NAME='squirrel' #this will be new name of executable binary
```
After you set variables you can run theese commands to install toolbox

```sh
git clone https://github.com/Swift-Squirrel/Squirrel-ToolBox.git
cd Squirrel-ToolBox
swift package resolve && swift build -c release && mv .build/release/SquirrelToolBox "$SQUIRREL_DIR/$SQUIRREL_NAME"
if [[ $? != 0 ]]; then echo "Installation failed"; else echo "Installation successful"; fi
```

After this you should make alias or export path in your *.bashrc*

## Usage

Toolbox can generate new templates for squirrel framework (`squirrel create`), manage running app (`squirrel serve`, `squirrel stop`, `squirrel ps`) or watch for changes in directory and rebuild, rerun on changes (`squirrel watch`)

For help run

```sh
squirrel help
```

For specific command help you can run `squirrel <command> -h` for example for create command it is

```sh
squirrel create -h
```

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Authors

* **Filip Klembara** - *Creator* - [github](https://github.com/LeoNavel)

See also the list of [contributors](https://github.com/Swift-Squirrel/Squirrel-ToolBox/CONTRIBUTORS) who participated in this project.

## License

This project is licensed under the Apache License Version 2.0 - see the LICENSE file for details
