/**
 * Git command safety for Pi tool calls.
 *
 * - Prevents git from opening an interactive editor in agent-run shell commands.
 * - Blocks --no-verify so hooks are fixed or surfaced instead of bypassed.
 */

const GIT_ENV_PREFIX =
  "export GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true GIT_MERGE_AUTOEDIT=no\n";

const NO_VERIFY_RE = /--no-verify\b/;
const GIT_COMMAND_RE = /(^|\s|[;&|])git(\s|$)/;

const BLOCK_REASON =
  "BLOCKED: --no-verify is not allowed. Git hooks should be fixed or surfaced to the user, not bypassed.";

function isBashToolCall(event: unknown): event is {
  toolName: string;
  input: { command: string };
} {
  if (!event || typeof event !== "object") return false;
  const maybe = event as { toolName?: unknown; input?: { command?: unknown } };
  return maybe.toolName === "bash" && typeof maybe.input?.command === "string";
}

export default function gitInterceptor(pi: {
  on: (eventName: "tool_call", handler: (event: unknown) => unknown) => void;
}) {
  pi.on("tool_call", (event) => {
    if (!isBashToolCall(event)) return;
    if (!GIT_COMMAND_RE.test(event.input.command)) return;

    if (NO_VERIFY_RE.test(event.input.command)) {
      return { block: true, reason: BLOCK_REASON };
    }

    if (!event.input.command.startsWith(GIT_ENV_PREFIX)) {
      event.input.command = GIT_ENV_PREFIX + event.input.command;
    }
  });
}
