# DOX CLI

[![Configure Test](https://github.com/dopxlab/dox-cli/actions/workflows/test-configure.yaml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/test-configure.yaml)
[![Action Test](https://github.com/dopxlab/dox-cli/actions/workflows/test-action.yaml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/test-action.yaml)
[![Latest Release](https://img.shields.io/github/v/release/dopxlab/dox-cli?style=flat-square)](https://github.com/dopxlab/dox-cli/releases)
[![License](https://img.shields.io/github/license/dopxlab/dox-cli?style=flat-square)](LICENSE)

**`dox-cli`** is a zero-config DevOps CLI that bootstraps your tools and DevOps actions in seconds. Easily configure common tools like Maven, Helm, Docker, Terraform, and more, or run pre-defined DevOps actions such as Helm packaging — all with a single command.

---

## ✨ Features

- One-line setup for common DevOps tools (`dox configure <tool>`)
- Action-based command system for Helm, Docker, Kubernetes, etc.
- Supports customization and overrides
- Easily integratable into CI/CD workflows (GitHub Actions, GitLab CI, etc.)
- Open source and extensible

---

## 📦 Installation

```bash
curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
bash install.sh
cp $HOME/.dox/bin/* /usr/local/bin/
```

Then verify:

```bash
dox --version
```

---

## ⚙️ `dox configure <tool>`

This command installs and configures a DevOps tool (e.g., Maven, Node.js, Helm, etc.) using a predefined script. It automatically handles downloading, setting up paths, and ensuring everything is ready to use.

### 🛠 Supported Tools

| Tool             | Command                    | Notes                                     |
|------------------|----------------------------|-------------------------------------------|
| Angular + Node   | `dox configure angular`    | Also installs Node.js                     |
| Maven + JDK      | `dox configure maven`      | Installs Maven and OpenJDK                |
| Helm             | `dox configure helm`       |                                            |
| Sonar Scanner    | `dox configure sonar-scanner` |                                          |
| Syft             | `dox configure syft`       | For container SBOM scanning               |
| Terraform        | `dox configure terraform`  |                                            |
| Yarn + Node      | `dox configure yarn`       | Also installs Node.js                     |
| Docker           | `dox configure docker`     |                                            |
| kubectl          | `dox configure kubectl`    | Kubernetes CLI                            |
| ArgoCD           | `dox configure argocd`     |                                            |

### ✅ Example

```bash
dox configure terraform
```

Installs Terraform and sets up necessary paths.

---

## 🚀 `dox <tool> <action>`

The `action` command runs predefined DevOps actions associated with a tool. For example, Helm actions such as `template` and `package`.

### 🧰 Supported Actions

| Tool   | Action     | Command                | Description                      |
|--------|------------|------------------------|----------------------------------|
| Helm   | `template` | `dox helm template`    | Renders Helm charts              |
| Helm   | `package`  | `dox helm package`     | Packages Helm charts into `.tgz` |

### ✅ Example

```bash
dox helm template
```

Renders the Helm chart in your current directory using `helm template`.

---

## ⚙️ Environment Variables

You can customize where `dox` installs tools and stores metadata by exporting the following variables before use:

```bash
export DOX_CLI_VERSION="v0.1.0"
export DOX_DIR="${DOX_DIR:-$HOME/.dox}"
export DOX_CUSTOM_DIR="${DOX_CUSTOM_DIR:-$DOX_DIR/customize}"
export DOX_RESOURCES_DIR="${DOX_RESOURCES_DIR:-$HOME/dox_resources}"
```

| Variable             | Default Value           | Description |
|----------------------|-------------------------|-------------|
| `DOX_CLI_VERSION`     | `v0.1.0`                | Version tag used for installation and updates |
| `DOX_DIR`             | `$HOME/.dox`            | Base directory for CLI binaries and configs   |
| `DOX_CUSTOM_DIR`      | `$DOX_DIR/customize`    | Directory for custom overrides                |
| `DOX_RESOURCES_DIR`   | `$HOME/dox_resources`   | External/custom resource directory            |

---

## 📄 License

This project is licensed under the **Apache License 2.0**.  
See the [LICENSE](LICENSE) file for details.

---

## 🙌 Contributions Welcome

Want to add support for more tools or actions? Open a PR or file an issue!

---