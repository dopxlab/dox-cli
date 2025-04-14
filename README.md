# DOX CLI

[![Build](https://github.com/dopxlab/dox-cli/actions/workflows/build.yml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/build.yml)
[![Configure Test](https://github.com/dopxlab/dox-cli/actions/workflows/test-configure.yaml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/test-configure.yaml)
[![Action Test](https://github.com/dopxlab/dox-cli/actions/workflows/test-action.yaml/badge.svg)](https://github.com/dopxlab/dox-cli/actions/workflows/test-action.yaml)
[![Latest Release](https://img.shields.io/github/v/release/dopxlab/dox-cli?style=flat-square)](https://github.com/dopxlab/dox-cli/releases)
[![License](https://img.shields.io/github/license/dopxlab/dox-cli?style=flat-square)](LICENSE)

**`dox-cli`** is a zero-config DevOps CLI that bootstraps your tools and DevOps actions in seconds. Easily configure common tools like Maven, Helm, Docker, Terraform, and more, or run pre-defined DevOps actions such as Helm packaging — all with a single command.

# 🧰 DOX CLI - Unified DevOps Tooling Framework

DOX CLI is a lightweight, extensible DevOps command-line tool that simplifies setup and orchestration of DevOps tools and actions across any CI/CD platform.

> 🔄 Works seamlessly with GitHub Actions, GitLab CI, Jenkins, Azure DevOps, and more.

---

## ✨ Why DOX?

Managing build tools, actions, and infrastructure can be **complex and inconsistent** across large teams and platforms. DOX solves this by introducing a **template-driven CLI** to manage configurations and common DevOps actions consistently.

### 💥 DevOps Challenges Solved

- 🔁 Repetitive tool installations across pipelines
- ⏳ No caching of build dependencies or tools
- 🔄 Inconsistent tool versions across environments
- 🔀 Difficult to switch between GitHub Actions, GitLab CI, Jenkins, etc.
- 🧩 Lack of centralized tool management
- 🏗️ No shared baseline for infrastructure scripts
- 🔐 Self-hosted/internal runners with secured repos are difficult to configure
- 🌐 Difficult to scale DevOps for large, distributed teams

---

## 🚀 How It Works

DOX CLI consists of two main modules:

### Module 1. ⚙️ Base CLI Scripts

These are reusable logic for parsing, variable resolution, folder structure, and execution engine.

### Module 2. 🧩 Custom Modules

Custom configuration templates you could provide here

- `configure/`: Contains configuration scripts for DevOps tools (e.g., Node, Maven, Terraform, Trivy, etc.)
- `action/`: Contains reusable action templates like Helm packaging, Docker build/push, ArgoCD deploy, etc.

---

# 🔧 Install the CLI

Just run the installation script:

```bash
curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh && bash install.sh
cp $HOME/.dox/bin/* /usr/local/bin/
```

Then verify:

```bash
dox --version
```

#### For the customization you can use the following Environment Variables (Refer [install.sh](./install.sh))


```bash
export DOX_DIR="${DOX_DIR:-$HOME/.dox}" # Base cli-framework
export DOX_CUSTOM_DIR="${DOX_CUSTOM_DIR:-$HOME/.dox/customize}" # customization part
export DOX_RESOURCES_DIR="${DOX_RESOURCES_DIR:-$HOME/dox_resources}" #the resources downloaded and kept in cache. If you are using Kubernetes you could make a persistnce volume with (RWX) and bind to the path
```

---

# 🧠 CLI Modules

## ⚙️ 1. Configuration Module

Command:  
```bash
dox configure <tool>
```

This uses the configuration template from the `customize/configure/<tool>.yaml`.

#### 📦 Configuration Template Format

```yaml
installation:
  dependencies:
    - dependency_1
    - dependency_2

  # download:
  #   version_archive: "/path/to/archive.tar.gz"
  # OR
  script:
    package_version: "install something"

  post_installation_script: |
    echo "Post-installation script executed"

configuration:
  default_version: "${LIBRARY_VERSION:-latest}"

  environments:
    INSTALL_DIR: "${install_dir}"
    PATH: "${install_dir}/bin"

  post_configuration_script: |
    echo "Printing installed version..."
```

 [Read More About Configuration Template](./docs/configuration.md)

#### 📚 Example: Maven Configuration | Which includes jdk installation

The configuration file for the maven setup is located at:


- [Maven Configuration](./customize/configure/maven.yaml): The Maven configuration file.
- [JDK Configuration Template](./customize/configure/jdk.yaml): The template used in Maven template for JDK configuration.

##### Note: If you need to customize the download from an internal repostiory like, nexus s3 or a pvc then adjust the [download_files.sh](./customize/download_files.sh) 

<details>
  <summary>Example: Maven Configuration</summary>

  ```yaml
installation:
  dependencies:
    - jdk
  download:
    "3.9.9": "https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz"
    "4.0.0-rc-3": "https://dlcdn.apache.org/maven/maven-4/4.0.0-rc-3/binaries/apache-maven-4.0.0-rc-3-bin.tar.gz"

configuration:
  default_version: "${MAVEN_VERSION:-3.9.9}"
  environments:
    M2_HOME: "${install_dir}"
    PATH: "${install_dir}/bin"
  post_configuration_script: |
    # Print the installed Maven version
    mvn -v
  ```
</details> 
    
<details>
  <summary>Click to expand the configuration log : dox configure maven</summary>
  
  ```bash
Run dox configure maven
  dox configure maven
  shell: /usr/bin/bash -e {0}
▶️ DOX CLI running...
Action: configure
Arguments: maven
--------------------------------------------------
DOX_RESOURCES_DIR         : /home/runner/dox_resources
CONFIGURE_FILE_PATH       : /home/runner/.dox/customize/configure
DOX_DIR                   : /home/runner/.dox
DOX_CUSTOM_DIR            : /home/runner/.dox/customize
ENV_PATH                  : env_path
ENV_EXPORT                : env_export
--------------------------------------------------
Configuring tool: maven
Installing dependency: jdk...
Dependency check completed, NO dependencies found for jdk.

----------------------------------------------------
Starting: Configuring jdk
----------------------------------------------------

Installing jdk...
Configuration file: /home/runner/.dox/customize/configure/jdk.yaml
You can override the version by providing a value for the variable JDK_VERSION
Evaluating library version: ${JDK_VERSION:-24}
Resolved jdk version: 24
Download URL: https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_linux-x64_bin.tar.gz
Installation Directory: /home/runner/dox_resources/jdk/24
jdk version 24 is not installed. Installing...
Downloading library from https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_linux-x64_bin.tar.gz
Downloading to temp file /tmp/tmp.fpFTKHzqxH
Downloading from: https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_linux-x64_bin.tar.gz
Downloaded successfully to /tmp/tmp.fpFTKHzqxH
Download completed. Extracting to /home/runner/dox_resources/jdk/24
Extracting tar.gz or tgz
Extraction successful. Library installed to /home/runner/dox_resources/jdk/24
Moved contents of the subdirectory and removed the empty subdirectory.

/home/runner/dox_resources/jdk/24
total 32
drwxr-xr-x  2 runner docker 4096 Apr  9 16:46 bin
drwxr-xr-x  5 runner docker 4096 Apr  9 16:46 conf
drwxr-xr-x  3 runner docker 4096 Apr  9 16:46 include
drwxr-xr-x  2 runner docker 4096 Apr  9 16:46 jmods
drwxr-xr-x 71 runner docker 4096 Apr  9 16:46 legal
drwxr-xr-x  5 runner docker 4096 Apr  9 16:46 lib
drwxr-xr-x  3 runner docker 4096 Apr  9 16:46 man
-rw-r--r--  1 runner docker 1210 Feb  6 00:39 release
Downloading to temp file /tmp/tmp.RhAO95RULd
Downloading from: https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
Downloaded successfully to /tmp/tmp.RhAO95RULd
Download completed. Extracting to /home/runner/dox_resources/maven/3.9.9
Extracting tar.gz or tgz
Extraction successful. Library installed to /home/runner/dox_resources/maven/3.9.9
Moved contents of the subdirectory and removed the empty subdirectory.

/home/runner/dox_resources/maven/3.9.9
total 48
-rw-r--r-- 1 runner docker 18920 Aug 14  2024 LICENSE
-rw-r--r-- 1 runner docker  5034 Aug 14  2024 NOTICE
-rw-r--r-- 1 runner docker  1279 Aug 14  2024 README.txt
drwxr-xr-x 2 runner docker  4096 Apr  9 16:46 bin
drwxr-xr-x 2 runner docker  4096 Apr  9 16:46 boot
drwxr-xr-x 3 runner docker  4096 Aug 14  2024 conf
drwxr-xr-x 4 runner docker  4096 Apr  9 16:46 lib

Downloaded and extracted the library to /home/runner/dox_resources/maven/3.9.9.
Setting environment variables for maven version 3.9.9...
Appended 'export M2_HOME="/home/runner/dox_resources/maven/3.9.9";' to env_export
Appended '/home/runner/dox_resources/maven/3.9.9/bin:' to env_path
ENV_EXPORT: export JAVA_HOME="/home/runner/dox_resources/jdk/24";export M2_HOME="/home/runner/dox_resources/maven/3.9.9";
ENV_PATH: /home/runner/dox_resources/jdk/24/bin:/home/runner/dox_resources/maven/3.9.9/bin:
No script found /home/runner/.dox/customize/configure/maven.yaml in installation.post_installation_script for maven. Skipping script execution.
Running configuration.post_configuration_script Script

Original script:
# Print the installed Maven version
mvn -v

Substituted script:
# Print the installed Maven version
mvn -v

WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by org.fusesource.jansi.internal.JansiLoader in an unnamed module (file:/home/runner/dox_resources/maven/3.9.9/lib/jansi-2.4.1.jar)
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
WARNING: Restricted methods will be blocked in a future release unless native access is enabled

Apache Maven 3.9.9 (8e8579a9e76f7d015ee5ec7bfcdc97d260186937)
Maven home: /home/runner/dox_resources/maven/3.9.9
Java version: 24, vendor: Oracle Corporation, runtime: /home/runner/dox_resources/jdk/24
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.8.0-1021-azure", arch: "amd64", family: "unix"

maven installation completed successfully.

Found env_export, sourcing the environment variables from it.
Found env_path, updating PATH.
  ```
</details> 


#### 🔬 Lab [Hand-on AWS CLI Installation & Configuration with DOX](./docs/aws-configuration.md)

---

## 🛠️ 2. Action Module

Command:  
```bash
dox <tool> <action>
```

This uses the action template from `customize/action/<tool>.yaml`.

#### 🧩 Action Template Format

```yaml
configure: |
  "<optional: configuration_command>" 

template:
  folder: "<optional: template_folder>" 
  variables:
    <template-variable-name>: "<optional: template-variable-value>" 
    # Example: "CUSTOM_VAR": "value"

actions:
  <action-name>: |
    "<optional: action_script>" # Optional, custom action name and script.
    # Users can define any action name (e.g., 'build', 'deploy', etc.) 
  # Example: "build": "npm run build"


```

### 🧠 Template Engine Module

The action module uses a dynamic template engine:

- All files in the `template.folder` will have `##VARIABLE_KEY##` replaced with the respective env variable.
- Example:  
  A Dockerfile can include `##BUILD_VERSION##` and will be auto-filled before execution.
- This makes the system extremely **modular** and **reusable**.

> The final resolved template is stored at `${template_folder}`.

---
 [Read More About Action Template](./docs/action.md)

#### 📚 Example: Helm Configuration | Which includes helm installation and template processing
The configuration file for the maven setup is located at:


- [Helm Action Template](./customize/action/helm.yaml): The template used to setup helm and configure actions
- [Helm Configuration](./customize/configure/helm.yaml): The Helm configuration file.
- [Template Folder](./customize/action/templates/helm): Template folder used by template engine 

<details>
  <summary>Example: Helm Action Template</summary>

  ```yaml
configure: |
  dox configure helm
  source ${DOX_CUSTOM_DIR}/global_envs.sh

template:
  folder: "${DOX_CUSTOM_DIR}/action/templates/helm" # ${template_folder} will be resolved path of the template folder 
  variables:
    BUILD_VERSION: "${BUILD_VERSION:-1.0.0}"
  ...

actions:
  template: |
    helm template ${template_folder}
  package: |
    helm package ${template_folder}
  push: |
    helm push $helm_chart $HELM_OCI_URL;
  ```
</details> 
    
<details>
  <summary>Click to expand the actions log : dox helm template</summary>
  
  ```bash
Run dox helm template
dox helm template
shell: /usr/bin/bash -e {0}
▶️ DOX CLI running...
Action: helm
Arguments: template
🛠️ Configuring Tool: helm
Running .configure Script

Original script:
dox configure helm
source ${DOX_CUSTOM_DIR}/global_envs.sh

Substituted script:
dox configure helm
source /home/runner/.dox/customize/global_envs.sh

▶️ DOX CLI running...
Action: configure
Arguments: helm
--------------------------------------------------
DOX_RESOURCES_DIR         : /home/runner/dox_resources
CONFIGURE_FILE_PATH       : /home/runner/.dox/customize/configure
DOX_DIR                   : /home/runner/.dox
DOX_CUSTOM_DIR            : /home/runner/.dox/customize
ENV_PATH                  : env_path
ENV_EXPORT                : env_export
--------------------------------------------------
Configuring tool: helm
Dependency check completed, NO dependencies found for helm.

----------------------------------------------------
Starting: Configuring helm
----------------------------------------------------

Installing helm...
Configuration file: /home/runner/.dox/customize/configure/helm.yaml
You can override the version by providing a value for the variable HELM_VERSION
Evaluating library version: ${HELM_VERSION:-3.17.2}
Resolved helm version: 3.17.2
Download URL: https://get.helm.sh/helm-v3.17.2-linux-amd64.tar.gz
Installation Directory: /home/runner/dox_resources/helm/3.17.2
helm version 3.17.2 is not installed. Installing...
Downloading library from https://get.helm.sh/helm-v3.17.2-linux-amd64.tar.gz
Downloading to temp file /tmp/tmp.rVtWdZOYXJ
Downloading from: https://get.helm.sh/helm-v3.17.2-linux-amd64.tar.gz
Downloaded successfully to /tmp/tmp.rVtWdZOYXJ
Download completed. Extracting to /home/runner/dox_resources/helm/3.17.2
Extracting tar.gz or tgz
Extraction successful. Library installed to /home/runner/dox_resources/helm/3.17.2
Moved contents of the subdirectory and removed the empty subdirectory.

/home/runner/dox_resources/helm/3.17.2
total 56812
-rw-r--r-- 1 runner docker    11373 Mar 13 16:25 LICENSE
-rw-r--r-- 1 runner docker     3699 Mar 13 16:25 README.md
-rwxr-xr-x 1 runner docker 58155160 Mar 13 16:23 helm

Downloaded and extracted the library to /home/runner/dox_resources/helm/3.17.2.
Setting environment variables for helm version 3.17.2...
grep: env_path: No such file or directory
Appended '/home/runner/dox_resources/helm/3.17.2:' to env_path
Warning: env_export file not found...!
ENV_PATH: /home/runner/dox_resources/helm/3.17.2:
No script found /home/runner/.dox/customize/configure/helm.yaml in installation.post_installation_script for helm. Skipping script execution.
Running configuration.post_configuration_script Script

Original script:
# Print the installed  version
helm version

Substituted script:
# Print the installed  version
helm version

version.BuildInfo{Version:"v3.17.2", GitCommit:"cc0bbbd6d6276b83880042c1ecb34087e84d41eb", GitTreeState:"clean", GoVersion:"go1.23.7"}

helm installation completed successfully.

Found env_path, updating PATH.
Template: /home/runner/.dox/customize/action/templates/helm exists
Temporary folder created at: /tmp/tmp.PCmEBRsN5N
Templates copied to: /tmp/tmp.PCmEBRsN5N
📄 Extracting variables from /home/runner/.dox/customize/action/helm.yaml... and generating utility script 🛠️

#!/bin/bash
set -e  # Exit on error

function replace_variables(){
    input_file=$1
    temp_file=/tmp/tmp.TxbgTcp0iz
    sed \
    -e "s|##BUILD_VERSION##|20250410.120736.0|g" \
    -e "s|##CHART_VERSION##|20250410.120736.0-helm|g" \
    -e "s|##GIT_DIR##|/home/runner/work/dox-cli/dox-cli\/.git|g" \
    -e "s|##NAMESPACE##|default|g" \
    -e "s|##DOCKER_IMAGE_PUSH_PREFIX##|docker.io\/myusername|g" \
    -e "s|##CUSTOM_PROJECT_VARIABLES##||g" \
    -e "s|##IMAGE_REPOSITORY##|docker.io\/myusername\/dox-cli|g" \
    -e "s|##IMAGE_TAG##|20250410.120736.0|g" \
    -e "s|##IMAGE_PULL_POLICY##|Always|g" \
    -e "s|##IMAGE_PULL_SECRETS##|image-pull-secret|g" \
    -e "s|##APPLICATION_NAME##|dox-cli|g" \
    -e "s|##APPLICATION_PORT##|8080|g" \
    -e "s|##APPLICATION_HEALTH_PORT##|8080|g" \
    -e "s|##APPLICATION_HEALTH_LIVENESS_PATH##|\/actuator\/info|g" \
    -e "s|##APPLICATION_HEALTH_LIVENESS_DELAY##|40|g" \
    -e "s|##APPLICATION_HEALTH_READINESS_PATH##|\/actuator\/health|g" \
    -e "s|##APPLICATION_HEALTH_READINESS_DELAY##|40|g" \
    -e "s|##RESOURCE_REQUESTS_CPU##|200m|g" \
    -e "s|##RESOURCE_REQUESTS_MEMORY##|512Mi|g" \
    -e "s|##RESOURCE_LIMITS_CPU##|500m|g" \
    -e "s|##RESOURCE_LIMITS_MEMORY##|1Gi|g" \
    -e "s|##AUTOSCALING_ENABLED##|true|g" \
    -e "s|##HELM_EXPERIMENTAL_OCI##|1|g" \
    -e "s|##HELM_OCI_URL##|oci:\/\/docker.io\/myusername|g" \
    -e "s|##INGRESS_HOST##||g" \
    -e "s|##IMAGE_PULL_SECRET##||g" \
    -e "s|##CONFIG_MAP_REF_NAME##||g" \
    -e "s|##SECRETS_REF_NAME##||g" \
    -e "s|##ENVIRONMENT_STAGE##|unknown|g" \
    -e "s|##PERSISTENT_VOLUME_CLAIM##||g" \
    -e "s|##MAINTAINER_NAME##|Joby Pooppillikudiyil|g" \
    -e "s|##MAINTAINER_EMAIL##|joby81@gmail.com|g" \
    -e "s|##ENVIORNMENT_STAGE##|unknown|g" \
    $input_file > $temp_file
    mv $temp_file $input_file
}
Processing: /tmp/tmp.PCmEBRsN5N/Chart.yaml
Processing: /tmp/tmp.PCmEBRsN5N/.helmignore
Processing: /tmp/tmp.PCmEBRsN5N/templates/_helpers.tpl
Processing: /tmp/tmp.PCmEBRsN5N/templates/ingress.yaml
Processing: /tmp/tmp.PCmEBRsN5N/templates/serviceaccount.yaml
Processing: /tmp/tmp.PCmEBRsN5N/templates/NOTES.txt
Processing: /tmp/tmp.PCmEBRsN5N/templates/deployment.yaml
Processing: /tmp/tmp.PCmEBRsN5N/templates/service.yaml
Processing: /tmp/tmp.PCmEBRsN5N/templates/hpa.yaml
Processing: /tmp/tmp.PCmEBRsN5N/templates/configmap.yaml
Processing: /tmp/tmp.PCmEBRsN5N/templates/secret.yaml
Processing: /tmp/tmp.PCmEBRsN5N/values.yaml
🚀 Executing action: 'helm template'
Running .actions.template Script

Original script:
helm template ${template_folder}

Substituted script:
helm template /tmp/tmp.PCmEBRsN5N

---
# Source: dox-cli/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
name: dox-cli
labels:
    helm.sh/chart: dox-cli-20250410.120736.0-helm
    app.kubernetes.io/name: dox-cli
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "20250410.120736.0-helm"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/maintainer-name: "Joby Pooppillikudiyil"
spec:
type: ClusterIP
ports:
    - name: defaulthttp
    port: 8080
    targetPort: defaulthttp
    protocol: TCP    
selector:
    app.kubernetes.io/name: dox-cli
    app.kubernetes.io/instance: release-name
---
# Source: dox-cli/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
name: dox-cli
labels:
    helm.sh/chart: dox-cli-20250410.120736.0-helm
    app.kubernetes.io/name: dox-cli
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "20250410.120736.0-helm"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/maintainer-name: "Joby Pooppillikudiyil"
spec:
selector:
    matchLabels:
    app.kubernetes.io/name: dox-cli
    app.kubernetes.io/instance: release-name
template:
    metadata:
    labels:
        app.kubernetes.io/name: dox-cli
        app.kubernetes.io/instance: release-name
    spec:
    serviceAccountName: default
    securityContext:
        fsGroup: 2000
        runAsGroup: 3000
        runAsUser: 1000
    containers:
        - name: dox-cli
        securityContext:
            runAsNonRoot: true
            runAsUser: 1000
        image: "docker.io/myusername/dox-cli:20250410.120736.0"
        imagePullPolicy: Always
        env:
        - name: POD_NAMESPACE
            valueFrom:
            fieldRef:
                fieldPath: metadata.namespace
        - name: IMAGE_VERSION
            value: "20250410.120736.0"          
        ports:
            - name: defaulthttp
            containerPort: 8080
            protocol: TCP            
        livenessProbe:
            initialDelaySeconds: 40
            failureThreshold: 5
            periodSeconds: 8
            successThreshold: 1
            timeoutSeconds: 2
            httpGet:
            path: /actuator/info
            port: 8080
        readinessProbe:
            initialDelaySeconds: 40
            failureThreshold: 5
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 3
            httpGet:
            path: /actuator/health
            port: 8080
        resources:
            limits:
            cpu: 500m
            memory: 1Gi
            requests:
            cpu: 200m
            memory: 512Mi
    volumes:
---
# Source: dox-cli/templates/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
name: dox-cli
labels:
    helm.sh/chart: dox-cli-20250410.120736.0-helm
    app.kubernetes.io/name: dox-cli
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "20250410.120736.0-helm"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/maintainer-name: "Joby Pooppillikudiyil"
spec:
scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: dox-cli
minReplicas: 1
maxReplicas: 10
metrics:
    - type: Resource
    resource:
        name: cpu
        target:
        type: Utilization
        averageUtilization: 80
    - type: Resource
    resource:
        name: memory
        target:
        type: Utilization
        averageUtilization: 80
✅ Actions completed for tool: helm
  ```
</details> 

## 📦 Example Use Case: GitHub Actions CI/CD

### ✅ `helm-template.yaml`

```yaml
name: Setup Node
on: [push]

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:

      # Step 1: Download and run the installation script
      - name: Install DOX CLI
        run: |
          curl -s -L -o install.sh https://github.com/dopxlab/dox-cli/releases/latest/download/install.sh && bash install.sh
          cp $HOME/.dox/bin/* /usr/local/bin/

      # Step 2: Add the new path for DOX to the $PATH and verify the installation
      - name: Verify DOX CLI installation
        run: |
          dox --version  # Verify that DOX CLI is now available

      # Step 3: DOX Action 1
      - name: dox helm template
        run: |
          dox helm template

```

---

## 📚 Configuration Templates

- `angular.yaml`
- `argocd.yaml`
- `docker.yaml`
- `helm.yaml`
- `jdk.yaml`
- `kubectl.yaml`
- `maven.yaml`
- `node.yaml`
- `sonar-scanner.yaml`
- `syft.yaml`
- `terraform.yaml`
- `trivy.yaml`
- `twistcli.yaml`
- `yarn.yaml`

---

## ⚙️ Actions Templates

- `helm` (template, package, push)
- `docker` (build, tag, push)
- `argocd` (app deployment)

To add more, just drop in a new `<tool>.yaml` into `customize/action` and use `dox <tool> <action>`!

---

## 🧠 Usage Scenarios

- 🚀 Instant setup of local DevOps tools without installing system-wide
- 🔁 Unified tool versioning across multiple CI/CD environments
- 🧱 Bootstrap test environments using CLI commands
- 🧪 Quickly provision QA/POC pipelines using the same DOX modules
- 🧰 Reuse DOX in developer laptops, pipelines, Docker builds
- 💻 Infrastructure automation via shell and template expansion

---

## 📝 License

This project is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

---

## 🙌 Contribute

Contributions are welcome! [Fork it](https://github.com/dopxlab/dox-cli), add your tool or action, and raise a PR 🎉

---

> Built with ❤️ by [Joby Pooppillikudiyil](https://github.com/jobythomasp)
