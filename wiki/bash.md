# `Bash`

<h2>Table of contents</h2>

- [What is `Bash`](#what-is-bash)
- [`Bash` syntax basics](#bash-syntax-basics)
  - [Run a command](#run-a-command)
  - [Pipe the `stdout`](#pipe-the-stdout)

## What is `Bash`

`Bash` is a command-line [shell](./shell.md#what-is-a-shell) and scripting language used to interact with the [operating system](./operating-system.md#what-is-an-operating-system).

Docs:

- [Bash reference manual](https://www.gnu.org/software/bash/manual/bash.html)
- [Learn Bash in Y minutes](https://learnxinyminutes.com/bash/)

## `Bash` syntax basics

### Run a command

[Run using the `VS Code Terminal`](./vs-code.md#run-a-command-using-the-vs-code-terminal):

```terminal
<command> <arguments>
```

Example:

[Run using the `VS Code Terminal`](./vs-code.md#run-a-command-using-the-vs-code-terminal):

```terminal
ls .
```

### Pipe the `stdout`

[Run using the `VS Code Terminal`](./vs-code.md#run-a-command-using-the-vs-code-terminal):

```terminal
<command-1> | <command-2>
```

Example:

[Run using the `VS Code Terminal`](./vs-code.md#run-a-command-using-the-vs-code-terminal):

```terminal
ls . | head -5
```
