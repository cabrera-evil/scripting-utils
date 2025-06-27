<!--

********************************************************************************

WARNING:

    DO NOT EDIT "scripting-utils/README.md"

    IT IS PARTIALLY AUTO-GENERATED

    (based on scripts, usage examples, and init logic)

********************************************************************************

-->

# Quick reference

- **Maintained by**:  
  [Douglas Cabrera](https://github.com/cabrera-evil)

- **Where to get help**:  
  [GitHub Issues](https://github.com/cabrera-evil/scripting-utils/issues)

# What is scripting-utils?

**scripting-utils** is a lightweight and portable collection of preconfigured Bash utilities for daily system tasks and DevOps workflows. These tools are designed to be symlinked globally for easy access from anywhere in the terminal.

The repository complements the [scripting](https://github.com/cabrera-evil/scripting) project by focusing on small, focused, reusable scripts that don’t require a full environment — just drop-in tools you can call from anywhere.

# How to use this repository

Clone the repository:

```bash
git clone https://github.com/cabrera-evil/scripting-utils
cd scripting-utils
```

Run the initialization script to set up symlinks:

```bash
./init.sh
```

> This will create symbolic links in your `/opt` or equivalent so you can use scripts like `amplify-tools`, `env-to-secret`, or `base64-clip` from anywhere.

# License

This project is released under the [MIT License](https://github.com/cabrera-evil/scripting-utils/blob/master/LICENSE).
