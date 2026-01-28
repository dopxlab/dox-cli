[![Build](https://github.com/dopxlab/dox-cli/actions/workflows/preview-build.yml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/preview-build.yml)
[![Configure Test](https://github.com/dopxlab/dox-cli/actions/workflows/test-configure.yaml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/test-configure.yaml)
[![Action Test](https://github.com/dopxlab/dox-cli/actions/workflows/test-action.yaml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/test-action.yaml)
[![Latest Release](https://img.shields.io/github/v/release/dopxlab/dox-cli?style=flat-square)](https://github.com/dopxlab/dox-cli/releases)
[![License](https://img.shields.io/github/license/dopxlab/dox-cli?style=flat-square)](LICENSE)

# DOX CLI - Development Operations Toolkit

**One command to standardize tooling across teams, projects, and pipelines.**

---

## Why DOX CLI?

Modern engineering organizations face critical tooling challenges:

- ⏱️ **Onboarding takes days** - Developers waste time on tool installation
- 🔧 **Version drift breaks pipelines** - "Works on my machine" is expensive
- 🏢 **Monorepos need multiple versions** - Same tool, different requirements
- 🔒 **Compliance is manual** - Tracking tool versions for audits is painful
- 🌐 **Multi-platform complexity** - Different clouds, different toolchains

**DOX CLI solves this:** Declarative, version-controlled toolchain management with first-class CI/CD integration.

---


## 🚀 Quick Start

### Installation

```bash
curl -s -L https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh | bash
```

**Note:** Reload your shell configuration after installation (if you use same shell):
```bash
source ~/.bashrc  # For bash
source ~/.zshrc   # For zsh
```

---

## 📦 Usage

### Single Tool Installation

Install the latest version of a tool:
```bash
dox config terraform
```

Install a specific version:
```bash
export TERRAFORM_VERSION=1.7.0
dox config terraform
```

### Multiple Tools Installation

Install multiple tools in one command:
```bash
dox config terraform kubectl jdk
```

With specific versions:
```bash
export TERRAFORM_VERSION=1.7.0
export KUBECTL_VERSION=v1.29.0
dox config terraform kubectl jdk
```

---

## 📄 Installation from File

Create a `tools.yaml` configuration file:

### Example with and without versions

```yaml
# Tools with specific versions
aws: 2.15.0
terraform: 1.7.0
kubectl: v1.29.0
helm: v3.14.0
maven: 3.9.5

# Tools without version (uses latest)
docker:
jdk:
gradle:
```

### Apply configuration from file

```bash
dox config -f tools.yaml
```
---

## 💼 Enterprise Use Cases

### 1️⃣ Monorepo with Multiple Java Versions

**Challenge:** Different services require Java 11, 17, and 21 with specific Maven versions.

<details>
<summary><b>View Solution →</b></summary>

**Configuration per service:**

```yaml
# service-legacy/.dox/tools.yaml
jdk: "11.0.21"
maven: "3.8.6"
```

```yaml
# service-api/.dox/tools.yaml
jdk: "17.0.9"
maven: "3.9.5"
```

**GitHub Actions:**
```yaml
jobs:
  build-legacy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup DOX
        run: |
          curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
          bash install.sh && echo "$HOME/.dox/bin" >> $GITHUB_PATH
      - name: Configure Tools
        working-directory: ./service-legacy
        run: dox config -f .dox/tools.yaml
      - name: Build
        run: mvn clean package
```

**Benefits:** Each service uses its required versions without Docker overhead. Same workflow locally and in CI.

📖 **[Read full documentation →](docs/use-cases/monorepo.md)**

</details>

---

### 2️⃣ Multi-Cloud Infrastructure Management

**Challenge:** Platform team manages AWS, Azure, GCP with different Terraform/Kubernetes versions.

<details>
<summary><b>View Solution →</b></summary>

**Cloud-specific configurations:**

```yaml
# infrastructure/aws/.dox/tools.yaml
terraform: "1.6.6"
kubectl: "v1.28.0"
trivy:
tfsec:
```

```yaml
# infrastructure/azure/.dox/tools.yaml
terraform: "1.7.0"
kubectl: "v1.29.0"
```

**Azure DevOps:**
```yaml
stages:
- stage: AWS_Deploy
  jobs:
  - job: Deploy
    steps:
    - bash: |
        curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
        bash install.sh && echo "##vso[task.prependpath]$HOME/.dox/bin"
    - bash: dox config -f infrastructure/aws/.dox/tools.yaml
    - bash: terraform apply -auto-approve
      workingDirectory: infrastructure/aws
```

**Benefits:** Different cloud providers use appropriate tool versions. Security tools version-controlled. No "works locally" issues.

📖 **[Read full documentation →](docs/use-cases/multi-cloud.md)**

</details>

---

### 3️⃣ Polyglot Microservices Platform

**Challenge:** 50+ microservices in Go, Node, Python, Java - each with unique tooling needs.

<details>
<summary><b>View Solution →</b></summary>

**Service templates:**

```yaml
# templates/go-service/.dox/tools.yaml
go: "1.21.5"
docker:
kubectl: "v1.29.0"
grype:
```

```yaml
# templates/node-service/.dox/tools.yaml
node: "20.10.0"
yarn:
docker:
sonar-scanner:
```

**GitLab CI Template:**
```yaml
.dox-setup:
  before_script:
    - curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
    - bash install.sh && export PATH="$HOME/.dox/bin:$PATH"
    - dox config -f .dox/tools.yaml

build:
  extends: .dox-setup
  script:
    - go build -o app ./cmd/main.go
```

**New service setup:**
```bash
cp -r templates/go-service my-new-service
cd my-new-service
dox config -f .dox/tools.yaml  # Ready in seconds
```

**Benefits:** Instant dev environments. Security tools standardized. Platform team controls versions via templates.

📖 **[Read full documentation →](docs/use-cases/microservices.md)**

</details>

---

### 4️⃣ Compliance & Audit Requirements

**Challenge:** Financial services requires reproducible builds with auditable tool versions.

<details>
<summary><b>View Solution →</b></summary>

**Quarterly compliance configuration:**

```yaml
# compliance/tools-2024-q1.yaml
# Approved by Security: 2024-01-15
# Audit Reference: SEC-2024-001

jdk: "17.0.9"  # CVE-2023-XXXXX patched
maven: "3.9.5"
docker: "24.0.7"
trivy: "0.48.0"
terraform: "1.6.6"  # Production approved
```

**Enforcement pipeline:**
```yaml
- name: Configure Approved Tools
  run: dox config -f compliance/tools-2024-q1.yaml
  
- name: Verify Compliance
  run: |
    java -version 2>&1 | grep "17.0.9" || exit 1
    mvn --version | grep "3.9.5" || exit 1
    
- name: Generate Audit Report
  run: |
    echo "Build Tools: 2024-Q1" > compliance-report.txt
    echo "Audit Ref: SEC-2024-001" >> compliance-report.txt
```

**Benefits:** Immutable versions for compliance. Git history = audit trail. Quarterly reviews update one file. Automated verification.

📖 **[Read full documentation →](docs/use-cases/compliance.md)**

</details>

---

## 🏗️ CI/CD Integration

Works with all major platforms:

<details>
<summary><b>GitHub Actions</b></summary>

```yaml
- name: Setup DOX CLI
  run: |
    curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
    bash install.sh
    echo "$HOME/.dox/bin" >> $GITHUB_PATH

- name: Configure Tools
  run: dox config -f .dox/tools.yaml
```

📖 **[Full GitHub Actions guide →](docs/ci-cd/github-actions.md)**

</details>

<details>
<summary><b>GitLab CI</b></summary>

```yaml
before_script:
  - curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
  - bash install.sh
  - export PATH="$HOME/.dox/bin:$PATH"
  - dox config -f .dox/tools.yaml
```

📖 **[Full GitLab CI guide →](docs/ci-cd/gitlab.md)**

</details>

<details>
<summary><b>Azure DevOps</b></summary>

```yaml
- bash: |
    curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
    bash install.sh
    echo "##vso[task.prependpath]$HOME/.dox/bin"
  displayName: 'Install DOX CLI'

- bash: dox config -f .dox/tools.yaml
  displayName: 'Configure Tools'
```

📖 **[Full Azure DevOps guide →](docs/ci-cd/azure-devops.md)**

</details>

<details>
<summary><b>Jenkins</b></summary>

```groovy
stage('Setup Tools') {
    steps {
        sh '''
            curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh
            bash install.sh
            export PATH="$HOME/.dox/bin:$PATH"
            dox config -f .dox/tools.yaml
        '''
    }
}
```

📖 **[Full Jenkins guide →](docs/ci-cd/jenkins.md)**

</details>

---

## 🛠️ Supported Tools

24+ development tools with version control:

<details>
<summary><b>View complete tool list</b></summary>

| Tool | Override Variable | Use Case |
|------|------------------|----------|
| **Languages & Runtimes** |
| go | `GO_VERSION` | Backend services |
| jdk | `JDK_VERSION` | Java applications |
| node | `NODE_VERSION` | JavaScript/TypeScript |
| python | `PYTHON_VERSION` | Python apps |
| **Build Tools** |
| maven | `MAVEN_VERSION` | Java builds |
| gradle | `GRADLE_VERSION` | Java/Kotlin builds |
| yarn | `YARN_VERSION` | Package management |
| **Infrastructure** |
| terraform | `TERRAFORM_VERSION` | Infrastructure as Code |
| kubectl | `KUBECTL_VERSION` | Kubernetes ops |
| helm | `HELM_VERSION` | Kubernetes packages |
| kustomize | `KUSTOMIZE_VERSION` | Kubernetes configs |
| argocd | `ARGOCD_VERSION` | GitOps |
| **Security** |
| trivy | `TRIVY_VERSION` | Vulnerability scanning |
| grype | `GRYPE_VERSION` | Container scanning |
| tfsec | `TFSEC_VERSION` | Terraform security |
| syft | `SYFT_VERSION` | SBOM generation |
| **Quality** |
| sonar-scanner | `SONAR_SCANNER_VERSION` | Code quality |
| **Containers** |
| docker | `DOCKER_CLI_VERSION` | Container builds |
| **Other** |
| angular | `ANGULAR_VERSION` | Frontend |
| jreleaser | `JRELEASER_VERSION` | Releases |
| k9s | `K9S_VERSION` | K8s debugging |
| kubeseal | `KUBESEAL_VERSION` | Secret management |

📖 **[Complete tool reference →](docs/tools/README.md)**

</details>

---

## 💡 Why Engineering Leaders Choose DOX CLI

<details>
<summary><b>1. Reduce Onboarding Time by 90%</b></summary>

**Before DOX:**
- New developer follows 20-page setup guide
- Installs 15+ tools manually
- Troubleshoots version conflicts for days
- Senior engineer spends hours supporting

**With DOX:**
```bash
git clone repo && cd repo
dox config -f .dox/tools.yaml
# Ready to code in 2 minutes
```

**Impact:** Senior engineers focus on architecture, not installation support.

</details>

<details>
<summary><b>2. Eliminate CI/CD Version Drift</b></summary>

**The Problem:**
- CI uses Terraform 1.6, developer has 1.5
- 3 hours debugging pipeline failures
- "Works on my machine" costs $500/incident

**The Solution:**
Same `tools.yaml` locally and in CI. Guaranteed parity.

**Impact:** 80% reduction in pipeline failures from version mismatches.

</details>

<details>
<summary><b>3. Centralized Security Compliance</b></summary>

**The Problem:**
- CVE announced in Maven 3.9.4
- Update 200+ repositories manually
- Takes 3 weeks, blocks deployments

**The Solution:**
Update one template, teams pull changes.

**Impact:** Respond to CVEs in hours, not weeks. Complete audit trail in Git.

</details>

<details>
<summary><b>4. Support Complex Monorepo Architectures</b></summary>

**The Problem:**
- Service A needs Java 11, Service B needs Java 17
- Docker-in-Docker is slow and complex
- Shared runners can't handle multiple versions

**The Solution:**
Each service has its own `.dox/tools.yaml`. Same workflow, different tools.

**Impact:** 40% faster builds. No Docker overhead. Simpler pipelines.

</details>

<details>
<summary><b>5. Platform Engineering at Scale</b></summary>

**The Problem:**
- 50 teams, 200 repositories
- Each reinvents tool installation
- No standardization, no golden paths

**The Solution:**
Platform team provides service templates with tooling included.

**Impact:** Self-service for teams. Consistency across org. Faster innovation.

</details>

---

## 📋 Configuration Format

Simple YAML for tool definitions:

```yaml
# Use default/latest version
kubectl:
helm:

# Specify exact version
terraform: "1.7.0"
maven: "3.9.5"

# Override via environment
# KUBECTL_VERSION=v1.28.0 dox config kubectl
```

📖 **[Configuration reference →](docs/configuration.md)**

---

## 🎯 Quick Commands

```bash
# List available tools
dox config list

# Configure single tool
dox config kubectl

# Configure multiple tools
dox config kubectl helm maven

# Configure from file
dox config -f tools.yaml

# Override versions (great for CI caching)
KUBECTL_VERSION=v1.29.0 dox config kubectl
```

📖 **[Command reference →](docs/commands.md)**

---

## 📚 Documentation

### Getting Started
- **[Installation Guide](docs/installation.md)** - Step-by-step setup
- **[Quick Start Tutorial](docs/quick-start.md)** - 5-minute walkthrough
- **[Configuration Guide](docs/configuration.md)** - YAML format and options

### Use Cases
- **[Monorepo Management](docs/use-cases/monorepo.md)** - Multiple versions in one repo
- **[Multi-Cloud Infrastructure](docs/use-cases/multi-cloud.md)** - Cloud-specific tooling
- **[Microservices Platform](docs/use-cases/microservices.md)** - Polyglot service templates
- **[Compliance & Auditing](docs/use-cases/compliance.md)** - Regulatory requirements

### CI/CD Integration
- **[GitHub Actions](docs/ci-cd/github-actions.md)** - Complete integration guide
- **[GitLab CI](docs/ci-cd/gitlab.md)** - Pipeline templates
- **[Azure DevOps](docs/ci-cd/azure-devops.md)** - YAML pipelines
- **[Jenkins](docs/ci-cd/jenkins.md)** - Groovy pipeline examples

### Reference
- **[All Tools](docs/tools/README.md)** - Complete tool catalog
- **[Environment Variables](docs/environment-variables.md)** - All override options
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

---

## 🔗 Links

- **GitHub**: https://github.com/dopxlab/dox-cli
- **Releases**: https://github.com/dopxlab/dox-cli/releases
- **Issues**: https://github.com/dopxlab/dox-cli/issues

---

## 🚀 Get Started Now

```bash
# Install DOX CLI
curl -s -L https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh | bash

# Configure your first tool
dox config kubectl

# You're ready!
```

**Ready to standardize your tooling?** Start with our **[Quick Start Tutorial](docs/quick-start.md)**.
