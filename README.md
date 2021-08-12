## Introduction

Bashbox is a wannabe bash _compiler_ which aims to help create modular and maintainable bash projects.

To give huge bash codebase a predictable form. Specially for the single script bash projects with thousands of lines of code.

Bashbox compiles your modular bash project into a single file along bringing a standard set of bash enforcements to ensure that your code is safe and less error-prone while you code and test before publishing it in an production environment.

And hey, we finally have _some sort of_ `std` library for bash too! Along the ability to create your own library and let others use it.

Bashbox design is `cargo` inspired but _for the bash buddies_, so I hope that tells the rest.

## Getting Started

Simply run the following command to install bashbox in your linux system:
```bash
curl -L "https://git.io/Jc9bH" | bash -s -- selfinstall
```

Now you are all set for creating awesome bash projects with it:
```bash
bashbox new project-name
```

## An example project

> `src/main.sh`
```bash
use foo;

function main() {
	echo "Hello world";
	foo "bar";
}
```

> `src/foo.sh`
```bash
function foo() {
	local _input="$1";
	echo "Hello my name is ${_input}";
}
```

You can run the project by:

```bash
bashbox run --release
```

If you want to pass some arguments:

```bash
bashbox run --release -- arg1 arg2 and-so-on
```

You can also execute run in build mode:

```bash
bashbox build --release --run -- arg1 arg2 and-so-on
```

Note: Don't pass `--run` in build command unless you want to auto-run it after compiling.

A simple example:

```bash
bashbox build --release
```

For more information try `bashbox --help`


## Compiling bashbox

It's simple, just run `./bashbox build --release` after cloning this repository and bashbox will compile itself.

## More things to write, this is incomplete at the moment

Please note that this project is very experimental and needs more work.

## Caveats

Don't do the followings

- Masking error:
```bash
if test "$(some_command --arg)" == "something"; then {
	do_something;
} fi

# Here due to the if statement it's impossible in bash to automatically catch the error within "$(some_command --arg)" subshell, which is why we need to assign it separately.
```
> Solution:
```bash
local _var_foo;
_var_foo="$(some_command --arg)";

if test "$_var_foo" == "something"; then {
	do_something;
} fi
```

- Undefined default variable in substitution:
```bash
local _argv="${1}"; # Can fail # Imagine the user never passed any argument and thus undefined by nature.

local _name_var="${SOME_ENV_VARIABLE}"; # Can fail # You're assuming that some environment variable is available but it might not be and thus undefined.
```
> Solution:
```bash
local _argv="${1:-}";

local _name_var="${SOME_ENV_VARIABLE:-}";

# We define a default value which is empty incase the variable was never defined just to make our program run. Later for safety all you should do is test whether your variable is empty or contains some data.
```
