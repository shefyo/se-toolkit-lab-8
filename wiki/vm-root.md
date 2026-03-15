# Connect to the VM as the user `root`

<h2>Table of contents</h2>

- [About connecting to the VM as the user `root`](#about-connecting-to-the-vm-as-the-user-root)
- [Add the host to `SSH`](#add-the-host-to-ssh)
- [Connect to the VM](#connect-to-the-vm)

## About connecting to the VM as the user `root`

Connecting to the VM as [the user `root`](./linux.md#the-user-root) is the first step after [creating your VM](./vm.md#create-a-vm).

Complete these steps:

<!-- no toc -->
1. [Add the host to `SSH`](#add-the-host-to-ssh)
2. [Connect to the VM](#connect-to-the-vm)

After connecting as the user `root`, see [Set up login as the non-root user `<user>`](./vm-non-root.md#about-setting-up-login-as-the-non-root-user-user).

## Add the host to `SSH`

> [!NOTE]
> See [host](./computer-networks.md#host).

1. Make sure you have [set up `SSH`](./ssh.md#set-up-ssh).
2. Get [`<your-vm-ip-address>`](./vm.md#your-vm-ip-address).
3. [Open the file](./vs-code.md#open-the-file):
   `~/.ssh/config`
4. Add this text at the end of the file.

   - `Linux`, `Windows`:

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

5. Replace [`<your-vm-ip-address>`](./vm.md#your-vm-ip-address) in the `~/.ssh/config` file.

## Connect to the VM

You can connect using the alias that you [added to your `SSH` config](#add-the-host-to-ssh).

1. To connect to the VM,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   ssh se-toolkit-vm
   ```

2. If this is your first time connecting:

   1. You will see a message:
      `The authenticity of host ... can't be established.`

   2. Type `yes` and press `Enter`.

3. After a successful login, you should see the [shell prompt](./shell.md#shell-prompt):

   ```terminal
   <user>@<your-vm-name>:~#
   ```

   The `<user>` is the same as you specified in your `~/.ssh/config` for the `Host se-toolkit-vm`.

   See:
   - [`<user>`](./operating-system.md#user-placeholder)
   - [`<your-vm-name>`](./vm.md#your-vm-name)

4. You are in the [home directory (`~`)](./file-system.md#home-directory-).
