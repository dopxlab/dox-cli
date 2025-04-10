# ⚙️ 1. Configuration Module
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

This YAML template is designed for managing the installation and configuration of software tools and libraries. It is divided into two main sections:

1. **installation** – This section is executed only once during the initial setup.
2. **configuration** – This section is executed each time the tool is configured or reconfigured.

---

## 1. **Installation Section** (Executed One Time During Installation)

The **installation** section is responsible for managing the dependencies, downloading, and installing the necessary software tools and libraries.

### i. **dependencies**
The `dependencies` key specifies any external dependencies that need to be installed before the main tool/library installation can take place. These dependencies must be installed beforehand for the installation process to proceed successfully.

- Example: If you're installing Maven, you would need to have JDK installed as a dependency.
  
```yaml
dependencies:
  - dependency_1
  - dependency_2
```

### ii. **download** (Optional)
This section allows you to provide a direct download URL for the tool or library. The specified archive file (e.g., `.tar.gz` or `.zip`) will be downloaded and used for installation.

- **version_archive**: Path to the archive file containing the tool or library.

```yaml
download:
  version_archive: "/path/to/archive.tar.gz"
```

### iii. **script** (Optional)
If you don't want to provide a direct download URL, you can use this section to install the software using package managers or custom installation commands.

- **package_version**: Specifies the package or software along with its version to be installed.

```yaml
script:
  package_version: "install something"
```

### iv. **post_installation_script**
The `post_installation_script` is a set of commands that runs immediately after the installation is completed. You can use this section to handle any post-installation tasks, such as setting up certificates, additional configurations, or cleanup.

- Example: After installing JDK, you might need to install company-specific certificates.

```yaml
post_installation_script: |
  echo "Post-installation script executed"
  # Example: Install company certificates to JDK
```

---

## 2. **Configuration Section** (Executed Each Time the Tool is Configured)

The **configuration** section manages the configuration settings for the installed tool or library. This part is executed each time the tool is configured or reconfigured.

### i. **default_version**
The `default_version` key specifies the default version of the tool or library to be used. It is set through an environment variable, allowing you to easily switch between different versions if needed. If no version is provided, the default version will be used.

- Example: `${LIBRARY_VERSION:-12}` means if the `LIBRARY_VERSION` environment variable is set, it will use that version; otherwise, it defaults to version `12`.

```yaml
default_version: "${LIBRARY_VERSION:-12}"
```

### ii. **environments**
The `environments` section defines environment variables that are required by the installed tool/library after it has been configured. These environment variables are essential for ensuring the tool operates correctly. 

- **${install_dir}**: This variable Refers to the directory where the tool/library was installed. This is often used for constructing file paths.
- **${install_dir}/bin**: Adds the tool’s `bin` directory to the system's PATH variable, allowing it to be accessed from anywhere in the terminal/command prompt.

```yaml
environments:
  INSTALL_DIR: "${install_dir}"
  PATH: "${install_dir}/bin"
```

### iii. **post_configuration_script**
The `post_configuration_script` section contains commands that run after the configuration process. These commands are useful for performing final checks, printing installed versions, or running any last-minute configuration tasks.

- Example: Print the installed version of the tool to verify the configuration was successful.

```yaml
post_configuration_script: |
  echo "Printing installed version..."
```

---

## Summary of Key Variables

### 1. **dependencies**
- Lists the dependencies that must be installed before the primary tool/library installation.

### 2. **download** (Optional)
- Provides a URL for downloading the tool/library if needed.

### 3. **script** (Optional)
- Defines installation commands for additional libraries or packages.

### 4. **post_installation_script**
- Executes commands after installation to configure the tool, install certificates, etc.

### 5. **default_version**
- Specifies the default version of the tool to be used, based on an environment variable or a fallback value.

### 6. **environments**
- Defines key environment variables such as `INSTALL_DIR` and `PATH` to ensure the tool functions correctly post-installation.

### 7. **post_configuration_script**
- A script that runs after configuration to perform final tasks like printing the installed version.

---

This template helps you automate the process of installing and configuring software tools and libraries, ensuring that you can easily manage dependencies, versioning, and environment variables.
