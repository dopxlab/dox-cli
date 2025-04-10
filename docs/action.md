# 🧩 Action Template Format

```yaml
configure: |
  #dox configure helm

template_folder: "<optional: template_folder>" 

variables:
  <variable-name>: "<optional: variable-value>" # Optional, users can define any custom variable and its value.

actions:
  <action-name>: |
  #action script

```

This YAML template allows you to configure custom actions and variables, as well as define specific templates for your deployment process. It provides flexibility for defining configuration commands, template folder paths, and custom variables for each action.

---

## 1. **configure**
This section allows you to define a custom configuration command to be run for the tool/library you are working with. The configuration command is optional and can be tailored to fit your requirements.

- **Example:** If you need to configure Helm, you could define `dox configure helm` as your configuration command.
  
```yaml
configure: |
  "<optional: configuration_command>" # Optional, configuration command (e.g., 'dox configure helm')
```

- If no configuration command is required, you can either leave this section out or specify your own command.

---

## 2. **template_folder** (Optional)
The `template_folder` key is optional and allows you to specify the folder where your templates are stored. If you provide a template folder name (e.g., `helm`), it will replace `${DOX_CUSTOM_DIR}/action/templates/helm` with the given folder.

- **Example:** If you provide `helm` as the template folder, it will reference `${DOX_CUSTOM_DIR}/action/templates/helm`.

```yaml
template_folder: "<optional: template_folder>"
```

---

## 3. **variables**
This section allows you to define any custom variables you need for your actions. Variables can be used to pass values into your scripts or commands and can be defined as key-value pairs.

- **Example:** You might define a `BUILD_VERSION` or `NAMESPACE` variable for your build or deployment process.

```yaml
variables:
  <variable-name>: "<optional: variable-value>" # Optional, users can define any custom variable and its value.
  # Example: "BUILD_VERSION": "1.0.0"
  # Example: "NAMESPACE": "production"
```

- Users can add any key-value pair, such as `"CUSTOM_VAR": "value"`, based on the needs of the process.

---

## 4. **actions**
The `actions` section allows you to define custom actions that you want to execute, such as build, deploy, or any other task. Each action has a corresponding script or command to run. You can name the action and provide a script for it.

- **Example:** You can define an action named `build` that runs `npm run build`, or a `deploy` action that uses `kubectl` to deploy a Kubernetes resource.

```yaml
actions:
  <action-name>: |
    "<optional: action_script>" # Optional, custom action name and script.
    # Example: "build": "npm run build"
    # Example: "deploy": "kubectl apply -f deployment.yaml"
    # Any custom action can be added here.
```

---

## Summary of Key Variables

### 1. **configure**
- Defines the optional configuration command that will be executed. Customize it as needed for your tool/library (e.g., `dox configure helm`).

### 2. **template_folder** (Optional)
- Specifies the folder that contains your templates. If a folder name like `helm` is provided, it replaces the default path `${DOX_CUSTOM_DIR}/action/templates/helm`.

### 3. **variables**
- A flexible section where users can define custom variables as key-value pairs. These variables can be used throughout the template for actions or configuration.

### 4. **actions**
- Defines custom actions to be executed with a corresponding script or command. You can name actions and provide the necessary commands for build, deploy, or other tasks.

---

This template offers flexibility in managing configuration commands, defining custom variables, and organizing specific actions for your deployment or management processes.