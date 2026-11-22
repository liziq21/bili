import { Plugin } from "@opencode/types"
import { existsSync, realpathSync } from "fs" // 引入 Node.js 原生文件存在检查工具
import { isAbsolute, relative, resolve } from "path"

// 工具参数由模型提供，不可信。先把路径解析成真实路径再确认它落在工作区内，
// 这样 "../../x.dart" 或指向区外的符号链接都不会让 analyze/format 碰到不属于本会话的文件。
const workspaceRoot = realpathSync(process.cwd())

const isInsideWorkspace = (filePath: string): boolean => {
  try {
    const rel = relative(workspaceRoot, realpathSync(resolve(filePath)))
    return rel !== "" && !rel.startsWith("..") && !isAbsolute(rel)
  } catch {
    return false
  }
}

export const DartQualityPlugin: Plugin = async ({ $ }) => {
  return {
    tool: {
      execute: {
        after: async (input, output) => {
          if (input.tool === "edit" || input.tool === "write") {
            const filePath = output.args?.filePath

            // 1. 确保文件路径存在、是 Dart 文件，且位于工作区内
            if (
              filePath &&
              filePath.endsWith(".dart") &&
              existsSync(filePath) &&
              isInsideWorkspace(filePath)
            ) {

              // 2. 严格执行你提供的 analyze 命令，利用 .nothrow() 让 Bash 自身的 || 和 exit 起作用
              await $`(dart analyze "${filePath}" 2>&1) || {
                echo "❌ Analysis failed" >&2
                exit 2
              }`.nothrow()

              // 3. 严格执行你提供的 format 命令
              await $`dart format "${filePath}" &>/dev/null || true`.nothrow()
              
            }
          }
        }
      }
    }
  }
}
