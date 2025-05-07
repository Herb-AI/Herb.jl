We are going to use the [MineRL](https://minerl.readthedocs.io/en/latest/) library in Julia. 

The installation process will be as follows:
1. Make sure Java 8 SDK is installed on your system, and it is in PATH. This is a requirement from the `minerl` package (probably because Minecraft runs Java :) )
2. Run the provided script in section [Install MineRL](#install-minerl).

## Install and Check Java SDK 8

If you already have Java SDK 8, you only have to make sure it is in PATH. You can check that by running `java -version` in cmd/bash/WSL. It should output `1.8.X_XXX` as a version.

For Linux and `WSL`(Windows Subsystem for Linux), simply run,
`sudo apt-get update; sudo apt-get install openjdk-8-jdk` to install Java `8`.

For Windows, or as an alternative option in Linux, download the appropriate version from here:
[Oracle JDK 8](https://www.oracle.com/nl/java/technologies/javase/javase8-archive-downloads.html)

Also, if you have the environment variable JAVA_HOME, make sure it is set to that same version of JDK.

## Using Windows natively

One may also set up the environment without WSL. The most important condition for MineRL is that the command `bash` is found.

Given this, one can just set a Windows Bash installation in PATH. The simplest one is to use Git Bash since you most likely have it installed (assuming any user reading this wiki is setting up the environment, and cloning the repo :))

To do this, simply add `C:\Program Files\Git\bin` to PATH. Similarly to Java, you can check if this is set up correctly, by running `bash` in `cmd`, and checking if Git Bash is loaded.

## Install MineRL

We now install MineRL and all the necessary utilities for the Python environment. We are using a Conda environment that is ran through Julia with `PyCall`.

You can install MineRL by running the following script:

```julia
using Pkg

Pkg.add("Conda")
using Conda
Conda.pip_interop(true)
Conda.pip("install", "setuptools==65.5.0")
Conda.pip("install", "pip==21")
Conda.pip("install", "wheel==0.38.0")
Conda.pip("install", "git+https://github.com/eErr0Re/minerl@prog-synth")
Conda.pip("install", "pyglet==1.5")

ENV["PYTHON"] = Conda.PYTHONDIR * "/python3"
Pkg.add("PyCall")
Pkg.build("PyCall")
```

It is important to note that the forked version of MineRL is necessary for running this repository. This is for multiple reasons, the main three being Gradle build configuration, the proper MineRL version (0.4 instead of 1.0.0 from the original repo), and modifying the environment slightly to be better suited for this repo's needs.

Rarely, the installation of MineRL can fail, especially if you are setting up the environment through Windows natively. Here are some potential fixes:

* Enable long paths: Navigate to the Registry Editor on Windows, then by following the path `Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem` set the registry `LongPathsEnabled` to 1.

* Downgrade HTTP version if cloning the repository fails: 
`git config --global http.version HTTP/1.1`
Make sure that you revert this change after installation, for security purposes:
`git config --global --unset http.version`

## Testing the code

You can test that it worked correctly by running `src/minecraft/getting_started_minerl.jl` in the `frangel-with-minerl` or `probe-with-minerl` branches.

Julia may crash while setting up the environment, with an error about `subprocess_call("...\julia.exe","-m", ...)`. This is because Julia is spawning a Python process using the `sys.executable` function to access the Python path. However, when Python is spawned by Julia, `sys.executable` points to `julia.exe` instead of `python.exe`.

To fix this, we have to change the code in the process_watcher.py to use the python.exe from the conda environment. Open `C:\Users\<your_username>\.julia\conda\3\x86_64\lib\site-packages\minerl\utils\process_watcher.py`, and on line `52`, replace `sys.executable` with `"C:\\Users\\<your_username>\\.julia\\conda\\3\\x86_64\\python.exe"`