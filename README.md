# AI Project Context Generator (`getfiles.sh`)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

```bash
curl https://raw.githubusercontent.com/butlanys/getfiles/main/getfiles.sh | bash
```

一个简单的 Bash 脚本，用于快速生成项目结构和选定文件内容的概览，旨在作为上下文提供给大型语言模型（LLM）或 AI 助手。

它会自动：

*   生成目录树（如果 `tree` 命令可用）。
*   抓取项目中的文件内容。
*   根据 `.gitignore` 文件排除文件和目录（需要 `git` 命令和在 Git 仓库中运行）。
*   允许你定义额外的自定义排除模式。
*   允许你指定只包含特定文件后缀的文件。
*   将生成的上下文保存到一个带有时间戳的文本文件中 (`ai_prompt_YYYYMMDD_HHMMSS.txt`)。

这对于向 AI 提供关于代码库的全面信息，以便进行调试、代码生成、文档编写或一般性分析非常有用，而无需手动复制粘贴大量文件。

## ✨ 功能特性

*   **目录树视图**: 使用 `tree` 命令（如果已安装）可视化项目结构。
*   **文件内容包含**: 自动读取并包含项目中文件的内容。
*   **.gitignore 感知**: 智能地排除 Git 配置中忽略的文件和目录（依赖 `git`）。
*   **自定义排除**: 通过编辑脚本顶部的 `CUSTOM_EXCLUDE_PATTERNS` 数组来添加你自己的排除规则（例如，`*.log`, `dist/`）。
*   **后缀过滤**: 通过编辑 `INCLUDE_SUFFIXES` 数组来选择只包含特定文件类型（例如，`py`, `js`, `md`）。
*   **自我忽略**: 脚本本身 (`getfiles.sh`) 和 `.git` 目录总是被排除。
*   **自动保存**: 将输出直接保存到带有日期和时间戳的文件中，方便管理。
*   **回退机制**: 如果 `git` 或 `tree` 命令不可用，脚本会尝试使用 `find` 命令，并打印警告。

## 🚀 为什么使用这个脚本？

*   **节省时间**: 无需手动浏览和复制粘贴多个文件。
*   **提供完整上下文**: 帮助 AI 更好地理解项目结构和代码依赖关系。
*   **结构化输出**: 生成的提示词具有清晰的结构（目录树、文件内容）。
*   **可配置**: 轻松调整排除项和包含的文件类型。

## 🛠️ 先决条件

*   **Bash**: 脚本是用 Bash 编写的，大多数 Linux、macOS 和 Windows (通过 WSL 或 Git Bash) 系统都自带。
*   **`git` (强烈推荐)**: 为了准确地遵循 `.gitignore` 规则，需要安装 `git` 并且脚本应在 Git 仓库的根目录运行。
*   **`tree` (可选但推荐)**: 为了获得更美观的目录树视图。如果未安装，脚本会使用 `find` 命令作为替代，并显示警告。
    *   在 Debian/Ubuntu 上: `sudo apt update && sudo apt install tree git`
    *   在 macOS 上 (使用 Homebrew): `brew install tree git`
    *   在 Fedora 上: `sudo dnf install tree git`

## ⚙️ 安装

1.  **获取脚本**:
    *   克隆仓库: `git clone <your-repo-url>`
    *   或者，直接下载 `getfiles.sh` 文件到你的项目根目录。
2.  **授予执行权限**: 在你的项目根目录打开终端，运行：
    ```bash
    chmod +x getfiles.sh
    ```

## 📝 使用方法

1.  **导航到项目**: 在终端中，`cd` 进入你的项目根目录。
2.  **(可选) 配置**: 如果需要，编辑 `getfiles.sh` 文件顶部的 `CUSTOM_EXCLUDE_PATTERNS` 和 `INCLUDE_SUFFIXES` 数组。
    ```bash
    # 示例: 排除所有 .log 文件和 build 目录
    CUSTOM_EXCLUDE_PATTERNS=("*.log" "build/")

    # 示例: 只包含 Python 和 Markdown 文件
    INCLUDE_SUFFIXES=("py" "md")

    # 如果 INCLUDE_SUFFIXES 为空数组，则包含所有未被排除的文件
    # INCLUDE_SUFFIXES=()
    ```
3.  **运行脚本**:
    ```bash
    ./getfiles.sh
    ```
4.  **检查输出**: 脚本将在终端显示一些信息，并将完整的 AI 提示词保存到一个名为 `ai_prompt_YYYYMMDD_HHMMSS.txt` 的文件中（例如 `ai_prompt_20250410_103600.txt`）。
5.  **提供给 AI**: 打开生成的 `.txt` 文件，复制其全部内容，然后粘贴到你的 AI 对话框中作为上下文或提示。

## 📄 输出结构

生成的 `ai_prompt_*.txt` 文件大致包含以下部分：

1.  **引导语**: 说明内容的性质和应用的排除规则。
2.  **项目结构 (目录树)**: 使用 `tree` 或 `find` 生成的目录列表。
3.  **文件内容**:
    *   对于每个包含的文件：
        *   文件路径标识 (`--- 文件路径: path/to/your/file ---`)
        *   文件内容本身
        *   分隔符 (`--------------------------------------------------`)
4.  **结束语**: 标记上下文结束。

## ⚠️ 限制

*   **自定义排除模式**: `CUSTOM_EXCLUDE_PATTERNS` 使用简单的 `grep` 模式匹配，可能不如 `.gitignore` 的语法强大或精确。它主要用于过滤 `git ls-files` 或 `find` 返回的路径字符串。
*   **`find` 回退**: 如果 `git` 不可用，使用 `find` 命令获取文件列表可能无法完全准确地遵循 `.gitignore` 的所有规则（特别是复杂的否定模式等）。
*   **二进制文件**: 脚本会尝试读取所有符合条件的文件。对于大型二进制文件，这可能会导致输出非常大或包含乱码。可以考虑使用 `CUSTOM_EXCLUDE_PATTERNS` 或 `INCLUDE_SUFFIXES` 来避免这种情况。

## 🤝 贡献

欢迎提出问题 (Issues) 和拉取请求 (Pull Requests)。如果你有改进脚本的想法或发现了 Bug，请随时贡献！

## 📜 许可证

本项目采用 [MIT 许可证](LICENSE)。 (你需要创建一个名为 `LICENSE` 的文件并将 MIT 许可证文本放入其中)
