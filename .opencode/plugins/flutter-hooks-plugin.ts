import { Plugin } from "@opencode/types"
import { realpathSync } from "fs" // 引入 Node.js 原生文件解析工具
import { isAbsolute, relative, resolve, sep } from "path"

// 工具参数由模型提供，不可信。先把路径解析成真实路径再确认它落在工作区内，
// 这样 "../../x.dart" 或指向区外的符号链接都不会让 analyze/format 碰到不属于本会话的文件。
const workspaceRoot = realpathSync(process.cwd())

// 返回真实路径；不存在或落在工作区外时返回 null。调用方必须使用这个真实路径，
// 否则校验之后被替换成符号链接的路径仍会指向区外。
const canonicalPathInWorkspace = (filePath: string): string | null => {
  try {
    const realPath = realpathSync(resolve(filePath))
    const rel = relative(workspaceRoot, realPath)
    const inside =
      rel !== "" && rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel)
    return inside ? realPath : null
  } catch {
    return null
  }
}

export const DartQualityPlugin: Plugin = async ({ $ }) => {
  return {
    tool: {
      execute: {
        after: async (input, output) => {
          if (input.tool === "edit" || input.tool === "write") {
            const filePath = output.args?.filePath

            // 1. 文件必须存在、是 Dart 文件，且真实路径位于工作区内
            const target =
              typeof filePath === "string" && filePath.endsWith(".dart")
                ? canonicalPathInWorkspace(filePath)
                : null

            if (target) {
              // 2. 严格执行你提供的 analyze 命令，利用 .nothrow() 让 Bash 自身的 || 和 exit 起作用
              await $`(dart analyze "${target}" 2>&1) || {
                echo "❌ Analysis failed" >&2
                exit 2
              }`.nothrow()

              // 3. 严格执行你提供的 format 命令
              await $`dart format "${target}" &>/dev/null || true`.nothrow()
            }
          }
        }
      }
    }
  }
}
