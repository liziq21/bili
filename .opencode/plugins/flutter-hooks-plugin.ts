import { Plugin } from "@opencode/types"
import { existsSync } from "fs" // 引入 Node.js 原生文件存在检查工具

export const DartQualityPlugin: Plugin = async ({ $ }) => {
  return {
    tool: {
      execute: {
        after: async (input, output) => {
          if (input.tool === "edit" || input.tool === "write") {
            const filePath = output.args?.filePath

            // 1. 确保文件路径存在，且操作系统中该文件确实存在
            if (filePath && filePath.endsWith(".dart") && existsSync(filePath)) {
              
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
