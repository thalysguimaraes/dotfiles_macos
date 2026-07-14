/**
 * Blocks manual edits to Cloudflare's generated worker-configuration.d.ts.
 *
 * Regenerate the file with `wrangler types` from the Worker project instead.
 */

const PROTECTED_FILE = "worker-configuration.d.ts";

const BLOCK_REASON =
  `BLOCKED: ${PROTECTED_FILE} is generated and must not be manually changed. ` +
  "Run `wrangler types` from the Worker project to regenerate it.";

const PROTECTED_FILE_RE = /(?:^|[^\w.-])worker-configuration\.d\.ts(?:$|[^\w.-])/;
const OUTPUT_REDIRECTION_RE = /(^|[^<=>-])>>?/;
const BASH_MUTATION_RE =
  /\b(?:tee|touch|cp|mv|rm|install|truncate|dd|rsync|python|python3|node|deno|ruby|bun|tsx|ts-node)\b|\b(?:sed|perl)\b[^\n]*(?:-i|--in-place)\b|\bgit\s+(?:checkout|restore|reset)\b/;
const SHELL_META_RE = /[;&|<>`]/;
const WRANGLER_TYPES_ONLY_RE =
  /^\s*(?:(?:env|export)\s+[^\s]+\s+)*((?:\.\/node_modules\/\.bin\/)?wrangler|(?:npx|bunx)\s+wrangler|(?:npm|pnpm|yarn|bun)\s+(?:exec\s+|dlx\s+)?wrangler)\s+types(?:\s+[^;&|<>`]*)?\s*$/;

function normalizeToolPath(path: string): string {
  return path.replace(/^@/, "").replaceAll("\\", "/");
}

function isProtectedPath(path: unknown): boolean {
  if (typeof path !== "string") return false;
  return normalizeToolPath(path).split("/").at(-1) === PROTECTED_FILE;
}

function isWriteOrEditToolCall(event: unknown): event is {
  toolName: string;
  input: { path?: unknown };
} {
  if (!event || typeof event !== "object") return false;
  const maybe = event as { toolName?: unknown; input?: { path?: unknown } };
  return (maybe.toolName === "write" || maybe.toolName === "edit") && !!maybe.input;
}

function isBashToolCall(event: unknown): event is {
  toolName: string;
  input: { command: string };
} {
  if (!event || typeof event !== "object") return false;
  const maybe = event as { toolName?: unknown; input?: { command?: unknown } };
  return maybe.toolName === "bash" && typeof maybe.input?.command === "string";
}

function referencesProtectedFile(command: string): boolean {
  return PROTECTED_FILE_RE.test(command);
}

function isWranglerTypesOnly(command: string): boolean {
  const normalized = command.replace(/\\\n/g, " ").trim();
  return !SHELL_META_RE.test(normalized) && WRANGLER_TYPES_ONLY_RE.test(normalized);
}

function appearsToModifyProtectedFile(command: string): boolean {
  if (!referencesProtectedFile(command)) return false;
  if (isWranglerTypesOnly(command)) return false;

  return OUTPUT_REDIRECTION_RE.test(command) || BASH_MUTATION_RE.test(command);
}

export default function workerConfigurationGuard(pi: {
  on: (
    eventName: "tool_call",
    handler: (
      event: unknown,
      ctx: { hasUI?: boolean; ui?: { notify?: (message: string, level: string) => void } },
    ) => unknown,
  ) => void;
}) {
  pi.on("tool_call", (event, ctx) => {
    if (isWriteOrEditToolCall(event)) {
      if (!isProtectedPath(event.input.path)) return;
      ctx.ui?.notify?.(`Blocked manual change to ${PROTECTED_FILE}; run wrangler types.`, "warning");
      return { block: true, reason: BLOCK_REASON };
    }

    if (!isBashToolCall(event)) return;
    if (!appearsToModifyProtectedFile(event.input.command)) return;

    ctx.ui?.notify?.(`Blocked manual change to ${PROTECTED_FILE}; run wrangler types.`, "warning");
    return { block: true, reason: BLOCK_REASON };
  });
}
