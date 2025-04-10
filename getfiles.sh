#!/bin/bash

# --- 配置 ---

# (可选) 自定义排除模式 (类似 .gitignore 的模式，但更简单，主要用于 grep 过滤)
# 例如: CUSTOM_EXCLUDE_PATTERNS=("*.log" "dist/" "node_modules/" "__pycache__")
CUSTOM_EXCLUDE_PATTERNS=()

# (可选) 只包含特定后缀的文件。如果留空数组，则包含所有找到的文件。
# 例如: INCLUDE_SUFFIXES=("sh" "py" "js" "ts" "md" "txt" "json" "yaml" "yml")
INCLUDE_SUFFIXES=()

# 输出文件名的基础部分
OUTPUT_FILENAME_BASE="ai_prompt"

# --- 内部变量 ---
SCRIPT_NAME="getfiles.sh"
IGNORE_FILE=".gitignore"
OUTPUT_SEPARATOR="--------------------------------------------------"

# --- 函数定义 ---

# 构建 grep -E 的排除模式
build_exclude_pattern() {
    local patterns=("$@")
    if [ ${#patterns[@]} -eq 0 ]; then
        echo ""
        return
    fi
    local pattern_string=""
    for pattern in "${patterns[@]}"; do
        # 简单转换：将 * 转换为 .*，并用 | 连接
        # 注意：这比 .gitignore 的语法简单得多，主要匹配路径片段
        local grep_pattern="${pattern//\*/.*}"
        pattern_string+="(${grep_pattern})|"
    done
    # 去掉最后的 |
    echo "${pattern_string%|}"
}

# 构建 grep -E 的包含后缀模式
build_suffix_include_pattern() {
    local suffixes=("$@")
    if [ ${#suffixes[@]} -eq 0 ]; then
        echo "" # 返回空表示不过滤后缀
        return
    fi
    local pattern_string=""
    for suffix in "${suffixes[@]}"; do
        # 确保匹配以点和后缀结尾
        pattern_string+="\.$suffix$|"
    done
    # 去掉最后的 |
    echo "${pattern_string%|}"
}


# --- 主逻辑 ---

# 1. 生成带时间戳的文件名
timestamp=$(date +'%Y%m%d_%H%M%S')
output_file="${OUTPUT_FILENAME_BASE}_${timestamp}.txt"

echo "正在生成 AI 提示词..."
echo "自定义排除模式: ${CUSTOM_EXCLUDE_PATTERNS[*]}"
echo "仅包含后缀: ${INCLUDE_SUFFIXES[*]:-(所有)}"
echo "输出将保存到: $output_file"

# 2. 开始捕获输出到文件
# 使用括号和重定向将所有 echo 输出捕获到文件
(
# --- Start AI Prompt Generation ---
echo "以下是项目结构和文件内容的详细信息。请分析此上下文。"
echo "请注意：排除了 '.git' 目录、本脚本 ('$SCRIPT_NAME')、'$IGNORE_FILE' 文件中定义的模式，以及以下自定义模式: ${CUSTOM_EXCLUDE_PATTERNS[*]}"
if [ ${#INCLUDE_SUFFIXES[@]} -gt 0 ]; then
    echo "此外，仅包含了具有以下后缀的文件: ${INCLUDE_SUFFIXES[*]}"
fi
echo ""

# --- Section 1: Directory Tree ---
echo "项目结构 (目录树):"
echo $OUTPUT_SEPARATOR
if command -v tree &> /dev/null; then
    # Tree 命令的排除可能不完全支持所有 gitignore 模式或自定义模式
    # 这里只排除 .git 和脚本本身，后续文件列表会应用更严格的过滤
    tree -I ".git|$SCRIPT_NAME" --noreport
else
    echo "[警告] 未找到 'tree' 命令。正在使用 'find' 生成基本结构。"
    echo "请安装 'tree' (例如 'sudo apt install tree' 或 'brew install tree') 以获得更好的可视化效果。"
    find . -not \( -path './.git' -prune \) -not \( -name "$SCRIPT_NAME" -prune \) -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
fi
echo $OUTPUT_SEPARATOR
echo ""

# --- Section 2: File Contents ---
echo "文件内容:"
echo $OUTPUT_SEPARATOR

# 获取初始文件列表
if [ -d ".git" ] || command -v git &> /dev/null; then
    echo "[信息] 使用 'git ls-files' 获取文件列表 (遵循 .gitignore)。"
    # 使用 git ls-files 获取基础列表，排除标准忽略和脚本自身
    base_files=$(git ls-files --cached --others --exclude-standard 2>/dev/null | grep -v "^$SCRIPT_NAME$")
else
    echo "[警告] 当前目录不是 Git 仓库或未找到 'git' 命令。"
    echo "[信息] 回退到使用 'find' 命令列出文件（可能不完全遵循 .gitignore 规则）。"
    # find 回退：查找所有文件，排除 .git 目录和脚本自身
    base_files=$(find . -type f -not -path './.git/*' -not -name "$SCRIPT_NAME")
fi

# 应用自定义排除
custom_exclude_pattern=$(build_exclude_pattern "${CUSTOM_EXCLUDE_PATTERNS[@]}")
if [ -n "$custom_exclude_pattern" ]; then
    echo "[信息] 应用自定义排除模式..."
    filtered_files=$(echo "$base_files" | grep -vE "$custom_exclude_pattern")
else
    filtered_files="$base_files"
fi

# 应用包含后缀过滤
suffix_include_pattern=$(build_suffix_include_pattern "${INCLUDE_SUFFIXES[@]}")
if [ -n "$suffix_include_pattern" ]; then
     echo "[信息] 应用后缀包含过滤器..."
     final_files=$(echo "$filtered_files" | grep -E "$suffix_include_pattern")
else
     final_files="$filtered_files"
fi

# 处理最终文件列表
if [ -z "$final_files" ]; then
    echo "未找到符合条件的文件。"
else
    processed_count=0
    # 逐个处理文件
    echo "$final_files" | while IFS= read -r file; do
        if [ -f "$file" ]; then # 再次确认文件存在且是普通文件
            echo "--- 文件路径: $file ---"
            # 使用 cat 输出文件内容，错误重定向
            cat "$file" 2>/dev/null || echo "[错误] 无法读取文件: $file"
            echo "" # 在文件内容后添加空行
            echo $OUTPUT_SEPARATOR
            processed_count=$((processed_count + 1))
        fi
    done
    echo "[信息] 处理了 $processed_count 个文件。"
fi


# --- End AI Prompt Generation ---
echo ""
echo "--- 上下文结束 ---"
echo "请基于以上项目结构和代码内容进行分析或回答问题。"

) > "$output_file" # 将括号内所有标准输出重定向到文件

# 3. 结束信息
if [ $? -eq 0 ]; then
  echo "成功！提示词已保存到 $output_file"
else
  echo "错误：生成提示词或保存文件时遇到问题。"
  # 如果失败，可以选择删除可能已部分创建的文件
  # rm -f "$output_file"
fi

exit 0
