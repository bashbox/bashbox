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

Swap `run` with `build` if you want a self contained single bash script.

For more information try `bashbox --help`


## Compiling bashbox

It's simple, just run `./bashbox build --release` after cloning this repository and bashbox will compile itself.

## More things to write, this is incomplete at the moment

Please note that this project is very experimental and needs more work.
