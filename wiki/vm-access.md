# VM access

<h2>Table of contents</h2>

- [About the VM access](#about-the-vm-access)
- [Set up `SSH`](#set-up-ssh)
  - [Create a new `SSH` key](#create-a-new-ssh-key)
  - [Find the `SSH` key files](#find-the-ssh-key-files)
  - [Start the `ssh-agent`](#start-the-ssh-agent)
  - [Verify the `SSH` setup](#verify-the-ssh-setup)
- [Add the host to `SSH`](#add-the-host-to-ssh)
- [Connect to the VM](#connect-to-the-vm)
- [Create the non-root user `<user>`](#create-the-non-root-user-user)
- [Set up the `SSH` key authentication for the user `<user>`](#set-up-the-ssh-key-authentication-for-the-user-user)
- [Connect to your VM by `SSH` as the user `<user>`](#connect-to-your-vm-by-ssh-as-the-user-user)
- [Harden the `SSH` config](#harden-the-ssh-config)
- [Update the local `SSH` config](#update-the-local-ssh-config)
- [Restart `sshd`](#restart-sshd)
- [Troubleshooting](#troubleshooting)
  - [`ping` times out](#ping-times-out)

## About the VM access

<!-- TODO first explicitly log in as root -->
<!-- TODO add LOCAL, REMOTE labels -->

> [!NOTE]
> Replace [`<user>`](./operating-system.md#user-placeholder) with the actual [username](./operating-system.md#username).

Setting up VM access involves two stages: connecting to the VM as [the user `root`](./linux.md#the-user-root) for the initial configuration, then creating a non-root user account with [`sudo`](./linux.md#sudo-group) privileges and reconfiguring [`SSH`](./ssh.md#what-is-ssh) to prevent login as the user `root`.

Complete these steps:

<!-- no toc -->
1. [Set up `SSH`](#set-up-ssh)
2. [Add the host to `SSH`](#add-the-host-to-ssh)
3. [Connect to the VM](#connect-to-the-vm)
4. [Create the non-root user `<user>`](#create-the-non-root-user-user)
5. [Set up the `SSH` key authentication for the user `<user>`](#set-up-the-ssh-key-authentication-for-the-user-user)
6. [Connect to your VM by `SSH` as the user `<user>`](#connect-to-your-vm-by-ssh-as-the-user-user)
7. [Harden the `SSH` config](#harden-the-ssh-config)
8. [Update the local `SSH` config](#update-the-local-ssh-config)
9. [Restart `sshd`](#restart-sshd)

## Set up `SSH`

Set up [`SSH`](./ssh.md#what-is-ssh) to connect to a [remote host](./computer-networks.md#remote-host).

Complete these steps:

<!-- no toc -->
1. [Check your current shell](./vs-code.md#check-the-current-shell-in-the-vs-code-terminal).
2. [Create a new `SSH` key](#create-a-new-ssh-key).
3. [Find the `SSH` key files](#find-the-ssh-key-files).
4. [Start the `ssh-agent`](#start-the-ssh-agent).
5. [Verify the `SSH` setup](#verify-the-ssh-setup).

### Create a new `SSH` key

Generate a key pair: a **private key** (secret) and a **public key** (safe to share).

We'll use the `ed25519` algorithm, which is the modern standard for security and performance.

Complete these steps:

1. To generate the key pair,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ssh-keygen -t ed25519 -C "se-toolkit-student" -f ~/.ssh/se_toolkit_key
   ```

   *Note:* You can replace `"se-toolkit-student"` with your email or another label.

   *Note:* `-f ~/.ssh/se_toolkit_key` sets a custom file path and name.

2. **Passphrase:** When asked `Enter passphrase`, you may type a secure password or press `Enter` for no passphrase.

   *Note:* If you set a passphrase, use `ssh-agent` to avoid retyping it on every connection.

<!-- TODO what does it mean to use ssh-agent -->

### Find the `SSH` key files

`SSH` keys are generated in pairs. You must know which file is which.

Because you used a custom name, your keys are named `se_toolkit_key` (private) and `se_toolkit_key.pub` (public).

1. To verify the keys were created,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ls ~/.ssh/se_toolkit_key*
   ```

2. You should see two files listed.

   The file ending in `.pub` contains the public key.

   Another file contains the private key.

3. To view the content of the public key file,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   cat ~/.ssh/se_toolkit_key.pub
   ```

   You should see something similar to this:

   ```terminal
   ssh-ed25519 AKdk38D3faWJnlFfalFJSKEFGG/vmLQ62Z+vpWCe5e/c2n37cnNc39N3c8qb7cBS+e3d se-toolkit-student
   ```

> [!IMPORTANT]
> Never share the private key.
> This is your secret identity.

### Start the `ssh-agent`

1. To start the agent and load your key,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/se_toolkit_key
   ```

### Verify the `SSH` setup

1. To list the loaded keys,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ssh-add -l
   ```

2. You should see your key fingerprint in the output.

3. If you see `The agent has no identities`, run the [start `ssh-agent` step](#start-the-ssh-agent) again.

## Add the host to `SSH`

> [!NOTE]
> See [host](./computer-networks.md#host).

1. [Get `<your-vm-ip-address>`](./vm.md#get-the-ip-address-of-the-vm).

2. [Open the file using `code`](./vs-code.md#open-the-file-or-the-directory-using-code):
   `~/.ssh/config`

3. Add this text at the end of the file:

   - `Linux`, `Windows` (`WSL`):

     ```text
     Host se-toolkit-vm
        HostName <your-vm-ip-address>
        User root
        IdentityFile ~/.ssh/se_toolkit_key
        AddKeysToAgent yes
     ```

   - `macOS`:

     ```text
     Host se-toolkit-vm
        HostName <your-vm-ip-address>
        User root
        IdentityFile ~/.ssh/se_toolkit_key
        AddKeysToAgent yes
        UseKeychain yes
     ```

4. Replace [`<your-vm-ip-address>`](./vm.md#your-vm-ip-address) in the `~/.ssh/config` file.

## Connect to the VM

You can connect using the alias that you [added to your `SSH` config](#add-the-host-to-ssh).

1. Disable `VPN`.

2. Connect your computer to the [`Wi-Fi` network](./computer-networks.md#wi-fi-network) `UniversityStudent`.

3. To connect to the VM,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ssh se-toolkit-vm
   ```

4. If this is your first time connecting:

   1. You will see a message:
      `The authenticity of host ... can't be established.`

   2. Type `yes` and press `Enter`.

5. After a successful login, you should see the [shell prompt](./shell.md#shell-prompt):

   ```terminal
   <user>@<your-vm-name>:~#
   ```

   The `<user>` is the same as you specified in your `~/.ssh/config` for the `Host se-toolkit-vm`.

   See:
   - [`<user>`](./operating-system.md#user-placeholder)
   - [`<your-vm-name>`](./vm.md#your-vm-name)

6. You are in the [home directory (`~`)](./file-system.md#home-directory-).

<!-- 7. If you use the `ms-vscode-remote.remote-ssh` extension in `VS Code`, the status bar should show that you are connected to a remote host.
   TODO explain how to use -->

## Create the non-root user `<user>`

> [!NOTE]
> Replace [`<user>`](./operating-system.md#user-placeholder) with the actual [username](./operating-system.md#username).

1. To create the user `<user>`,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   adduser <user>
   ```

2. To add the user `<user>` to the [`sudo` group](./linux.md#sudo-group),

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   usermod -aG sudo <user>
   ```

## Set up the `SSH` key authentication for the user `<user>`

> [!NOTE]
> Replace [`<user>`](./operating-system.md#user-placeholder) with the actual [username](./operating-system.md#username).

1. To create the `.ssh/` directory for the user `<user>`,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   mkdir -p /home/<user>/.ssh
   ```

2. To copy the authorized keys from [the user `root`](./linux.md#the-user-root),

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   cp /root/.ssh/authorized_keys /home/<user>/.ssh/
   ```

3. To set the correct ownership on the `.ssh/` directory,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   chown -R <user>:<user> /home/<user>/.ssh
   ```

   > 🟦 **Note**
   >
   > See [Change the owner and group (recursive)](./linux-administration.md#change-the-owner-and-group-recursive).

4. To set the correct permissions on the `.ssh/` directory,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   chmod 700 /home/<user>/.ssh
   ```

   > 🟦 **Note**
   >
   > See [Set the permissions](./linux-administration.md#set-the-permissions).

   <!-- TODO why these permissions are correct? -->

5. To set the correct permissions on the `authorized_keys` file,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   chmod 600 /home/<user>/.ssh/authorized_keys
   ```

   <!-- TODO why these permissions are correct? -->

## Connect to your VM by `SSH` as the user `<user>`

> [!NOTE]
> Replace [`<user>`](./operating-system.md#user-placeholder) with the actual [username](./operating-system.md#username).

1. [Open a new `VS Code Terminal`](./vs-code.md#open-a-new-vs-code-terminal).

2. To connect as the user `<user>`,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ssh -i ~/.ssh/se_toolkit_key <user>@<your-vm-ip-address>
   ```

   Replace the placeholder [`<your-vm-ip-address>`](./vm.md#your-vm-ip-address).

3. Confirm the connection did not prompt for a password.

## Harden the `SSH` config

<!-- TODO what are the implications -->
<!-- TODO check there's this file at all with this content -->
<!-- TODO keep root login but make it non-default? -->

1. To open the [`SSH`](./ssh.md#what-is-ssh) config,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   sudo nano /etc/ssh/sshd_config
   ```

2. Find the line `PermitRootLogin` and set it to:

   ```text
   PermitRootLogin no
   ```

3. Find the line `PasswordAuthentication` and set it to:

   ```text
   PasswordAuthentication no
   ```

4. Save (`Ctrl+O`, `Enter`).

5. Exit (`Ctrl+X`).

## Update the local `SSH` config

> [!NOTE]
> Replace [`<user>`](./operating-system.md#user-placeholder) with the actual [username](./operating-system.md#username).

1. [Open the file](./vs-code.md#open-the-file):
   `~/.ssh/config`

2. Find the `se-toolkit-vm` entry.

3. Change `User root` to `User <user>`.

   Replace the placeholder `<user>`.

   The result should look like this:

   - `Linux`, `Windows`:

     ```text
     Host se-toolkit-vm
        HostName <your-vm-ip-address>
        User <user>
        IdentityFile ~/.ssh/se_toolkit_key
        AddKeysToAgent yes
        PasswordAuthentication no
     ```

   - `macOS`:

     ```text
     Host se-toolkit-vm
        HostName <your-vm-ip-address>
        User <user>
        IdentityFile ~/.ssh/se_toolkit_key
        AddKeysToAgent yes
        PasswordAuthentication no
        UseKeychain yes
     ```

## Restart `sshd`

1. To validate the config,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   sudo sshd -t
   ```

   If the command prints no output, the config is valid. If it prints errors, fix them in `/etc/ssh/sshd_config` before continuing.

2. To restart the service,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   sudo systemctl restart sshd
   ```

3. To verify you can still connect,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ssh se-toolkit-vm
   ```

4. Confirm you are logged in as the user `<user>`, not [the user `root`](./linux.md#the-user-root).

> [!IMPORTANT]
> Keep your current `SSH` session open until you confirm the new connection works. If the new connection fails, use the existing session to fix the config.

<!-- TODO
check authorized_keys doesn't have autochecker key (tail -n 5)

add autochecker public key
-->

## Troubleshooting

<!-- TODO refactor -->

### `ping` times out

1. Recreate the VM with the same public key as [before](#create-a-new-ssh-key).

If you can't connect:

1. [Go to the VM page](./vm.md#go-to-the-vm-page).
2. Verify the VM is in `Running` status.
3. Verify the VM IP address has not changed.
4. To test the [`SSH`](./ssh.md) connection in verbose mode,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ssh -v se-toolkit-vm
   ```

5. If you get `Permission denied (publickey)`, check:
   1. Your public key was added to the VM configuration.
   2. `IdentityFile` in your `SSH` config points to the correct private key.
   3. Your private key file permissions are correct (`chmod 600 ~/.ssh/se_toolkit_key` on `Linux`/`macOS`/`WSL`).
6. Ask the TA to help and show them:
   1. The VM page.
   2. The output of `ssh -v se-toolkit-vm`.
   3. Your [`VS Code Terminal`](./vs-code.md#vs-code-terminal).
