/**
 * Paste Image Plus
 *
 * Replaces the built-in Ctrl+V image paste with a version that also handles
 * file references on the clipboard (Finder "Copy" on macOS, text/uri-list on
 * Wayland) and gives feedback instead of failing silently when the clipboard
 * has nothing pasteable.
 *
 * Live input attachment (Claude Code-style):
 *   Image paths in the live editor are replaced IN PLACE with `[Image #n]`
 *   tokens as soon as they resolve to a real image file (on paste, drop, or
 *   typing). The token lives in the editor text itself — there is no separate
 *   preview panel. Each token is backed by cached base64 image data so that on
 *   submit the bytes are attached as real images and reach the model as pixels.
 *
 *   - Ctrl+V with clipboard image bytes  -> writes a temp file and inserts
 *     `[Image #n]` at the cursor.
 *   - Ctrl+V with a Finder-copied file    -> inserts `[Image #n]` per file.
 *   - A path typed or dropped into the editor is converted to `[Image #n]`
 *     live, debounced over terminal input.
 *
 *   On submit, the `input` handler resolves every `[Image #n]` token in order
 *   (plus any leftover literal paths from non-TUI modes / fast typing), attaches
 *   the base64 bytes as flat `ImageContent`, and renumbers tokens to match the
 *   images array so `[Image #k]` always points at the k-th image.
 */

import { spawnSync } from "child_process";
import { randomUUID } from "crypto";
import { existsSync, readFileSync, statSync, writeFileSync } from "fs";
import { homedir, tmpdir } from "os";
import { join } from "path";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { ImageContent } from "@earendil-works/pi-ai";

function clipboardFilePaths(): string[] {
	if (process.platform === "darwin") {
		const r = spawnSync(
			"osascript",
			["-e", "POSIX path of (the clipboard as «class furl»)"],
			{ encoding: "utf-8", timeout: 3000 },
		);
		// AppleScript coerces plain text to furl, so only accept real paths.
		const p = r.status === 0 ? r.stdout.trim() : "";
		return p && existsSync(p) ? [p] : [];
	}
	if (process.platform === "linux") {
		const r = spawnSync("wl-paste", ["--type", "text/uri-list"], {
			encoding: "utf-8",
			timeout: 3000,
		});
		if (r.status !== 0) return [];
		return r.stdout
			.split(/\r?\n/)
			.map((l) => l.trim())
			.filter((l) => l.startsWith("file://"))
			.map((l) => decodeURIComponent(l.replace(/^file:\/\//, "")))
			.filter((p) => existsSync(p));
	}
	return [];
}

async function clipboardImageToTempFile(): Promise<string | null> {
	// Reuse pi's own clipboard-image reader so behavior matches the built-in.
	try {
		const mod = await import(
			"@earendil-works/pi-coding-agent/dist/utils/clipboard-image.js"
		);
		const image = await mod.readClipboardImage();
		if (!image) return null;
		const ext = mod.extensionForImageMimeType?.(image.mimeType) ?? "png";
		const filePath = join(tmpdir(), `pi-clipboard-${randomUUID()}.${ext}`);
		writeFileSync(filePath, Buffer.from(image.bytes));
		return filePath;
	} catch {
		// Import blocked or reader failed; try a macOS-native fallback.
	}
	if (process.platform === "darwin") {
		const filePath = join(tmpdir(), `pi-clipboard-${randomUUID()}.png`);
		const script = `set f to POSIX file ${JSON.stringify(filePath)}
try
	set imgData to the clipboard as «class PNGf»
on error
	return "no"
end try
set out to open for access f with write permission
write imgData to out
close access out
return "ok"`;
		const r = spawnSync("osascript", ["-e", script], {
			encoding: "utf-8",
			timeout: 5000,
		});
		if (r.status === 0 && r.stdout.trim() === "ok") return filePath;
	}
	return null;
}

const IMAGE_EXT_RE = /\.(png|jpe?g|webp|gif)$/i;
const QUOTED_IMAGE_RE = /(["'])([^"'\n]+?\.(?:png|jpe?g|webp|gif))\1/gi;
const MAX_ATTACH_BYTES = 5 * 1024 * 1024;

function mediaTypeForPath(p: string): string {
	const ext = p.toLowerCase().split(".").pop();
	if (ext === "jpg" || ext === "jpeg") return "image/jpeg";
	if (ext === "webp") return "image/webp";
	if (ext === "gif") return "image/gif";
	return "image/png";
}

function expandHome(p: string): string {
	return p.startsWith("~/") ? join(homedir(), p.slice(2)) : p;
}

type ImagePathMatch = { match: string; path: string };

/**
 * Find existing image-file paths in text. Handles quoted paths,
 * backslash-escaped spaces, and unquoted paths with spaces mid-sentence by
 * anchoring on path-like starts (/, ~/, ./) and extending across whitespace
 * until existsSync confirms a real file. Never matches `[Image #n]` tokens.
 */
function findImagePaths(text: string): ImagePathMatch[] {
	const seen = new Set<string>();
	const out: ImagePathMatch[] = [];
	const add = (match: string, path: string) => {
		if (!seen.has(match)) {
			seen.add(match);
			out.push({ match, path });
		}
	};

	// Quoted paths: "...png" or '...png'
	for (const m of text.matchAll(QUOTED_IMAGE_RE)) {
		const path = expandHome(m[2]);
		if (existsSync(path)) add(m[0], path);
	}

	for (const line of text.split(/\r?\n/)) {
		const tokens = line.trim().split(/\s+/).filter(Boolean);
		for (let i = 0; i < tokens.length; i++) {
			const t = tokens[i];
			// Backslash-escaped spaces: /tmp/ppt\ green.png arrives as one "word" per
			// shell habits only when spaces are escaped inside the token stream.
			if (IMAGE_EXT_RE.test(t) && t.includes("\\ ") === false && t.includes("\\")) {
				const unescaped = expandHome(t.replace(/\\(.)/g, "$1"));
				if (existsSync(unescaped)) {
					add(t, unescaped);
					continue;
				}
			}
			if (!/^(\/|~\/|\.\/)/.test(t)) continue;
			// Extend rightward until a token ends with an image extension and the
			// joined candidate exists on disk.
			for (let j = i; j < tokens.length; j++) {
				if (!IMAGE_EXT_RE.test(tokens[j])) continue;
				const candidate = tokens.slice(i, j + 1).join(" ");
				const path = expandHome(candidate.replace(/\\(.)/g, "$1"));
				if (existsSync(path)) {
					add(candidate, path);
					i = j;
					break;
				}
			}
		}
	}
	return out;
}

type AttachData = { data: string; mimeType: string };

// --- Live attachment state --------------------------------------------------
// Tokens `[Image #n]` in the editor are backed by entries here. The editor is
// text-only, so the token *is* the in-input representation of the attachment
// (no separate preview panel). On submit we resolve every token to its bytes.
const attachments = new Map<number, AttachData>();
let nextAttachIndex = 1;
let unsubTerminalInput: (() => void) | undefined;
let convertTimer: ReturnType<typeof setTimeout> | undefined;
let convertedDisposed = false;

function readAttachData(path: string): AttachData | null {
	try {
		if (statSync(path).size > MAX_ATTACH_BYTES) return null;
		return { data: readFileSync(path).toString("base64"), mimeType: mediaTypeForPath(path) };
	} catch {
		return null;
	}
}

/** Drop attachments whose `[Image #n]` token no longer appears in the text. */
function pruneAttachments(text: string): void {
	const present = new Set<number>();
	for (const m of text.matchAll(/\[Image #(\d+)\]/g)) {
		present.add(Number(m[1]));
	}
	for (const idx of [...attachments.keys()]) {
		if (!present.has(idx)) attachments.delete(idx);
	}
}

/** Next sequential token index for a new attachment. */
function nextIndex(): number {
	return nextAttachIndex++;
}

/**
 * Replace every literal image path still present in the editor with an
 * `[Image #n]` token, backing the token with base64 image data. Runs live on
 * paste/drop/type. Tokens already in the text are left untouched (and never
 * match `findImagePaths`, which ignores `[Image #n]`).
 */
function convertPathsToTokens(ctx: ExtensionContext): void {
	if (convertedDisposed || ctx.mode !== "tui") return;
	let text: string;
	try {
		text = ctx.ui.getEditorText();
	} catch {
		return;
	}
	const paths = findImagePaths(text);
	if (paths.length === 0) {
		pruneAttachments(text);
		return;
	}
	// Replace longest matches first so a longer anchored path can't be split by a
	// shorter overlapping one (mirrors the submit-time transform).
	let newText = text;
	let added = 0;
	for (const { match, path } of paths.sort((a, b) => b.match.length - a.match.length)) {
		const data = readAttachData(path);
		if (!data) {
			// Over the limit or unreadable: leave the literal path in place so the
			// submit handler can surface the over-size notice and pass it as text.
			continue;
		}
		const idx = nextIndex();
		attachments.set(idx, data);
		newText = newText.split(match).join(`[Image #${idx}]`);
		added++;
	}
	if (added > 0) {
		try {
			// setEditorText forces the cursor to the end. Pasted/dropped/typed paths
			// are normally at (or near) the end of the input, so the cursor ends up
			// where the user already is — the jarring mid-text case is rare.
			ctx.ui.setEditorText(newText);
		} catch {
			// Editor unavailable; live conversion is best-effort.
		}
	}
	pruneAttachments(newText);
}

/**
 * Resolve the final message: convert any leftover literal paths to tokens,
 * then resolve every `[Image #n]` token in textual order into an image, and
 * renumber tokens so `[Image #k]` points at the k-th image (offset by any
 * images already supplied out-of-band, e.g. via RPC).
 */
function finalizeForSubmit(
	text: string,
	existingImages: ImageContent[] | undefined,
): { text: string; images: ImageContent[] } {
	let working = text;

	// Convert leftover literal paths (non-TUI modes, or fast typing before the
	// debounced converter ran). Same longest-first rule as the live converter.
	const leftover = findImagePaths(working);
	if (leftover.length > 0) {
		for (const { match, path } of leftover.sort((a, b) => b.match.length - a.match.length)) {
			const data = readAttachData(path);
			if (!data) continue;
			const idx = nextIndex();
			attachments.set(idx, data);
			working = working.split(match).join(`[Image #${idx}]`);
		}
	}

	const base = existingImages?.length ?? 0;
	const images: ImageContent[] = [...(existingImages ?? [])];
	const tokenRe = /\[Image #(\d+)\]/g;
	let result = "";
	let last = 0;
	let k = base;
	for (const m of working.matchAll(tokenRe)) {
		if (m.index === undefined) continue;
		result += working.slice(last, m.index);
		const att = attachments.get(Number(m[1]));
		if (att) {
			k++;
			images.push({ type: "image", data: att.data, mimeType: att.mimeType } as ImageContent);
			result += `[Image #${k}]`;
		} else {
			// Unresolved token (e.g. left over from a prior session): keep as text.
			result += m[0];
		}
		last = m.index + m[0].length;
	}
	result += working.slice(last);

	// Submit is the end of this message — clear attachment state for the next one.
	attachments.clear();
	nextAttachIndex = 1;
	return { text: result, images };
}

/** Insert the token(s) at the cursor using pi's bracketed-paste path. */
function insertTokensAtCursor(ctx: ExtensionContext, tokens: string[]): void {
	const s = tokens.join(" ");
	try {
		ctx.ui.pasteToEditor(s);
	} catch {
		// Fallback: append at end.
		const cur = ctx.ui.getEditorText();
		const sep = cur && !cur.endsWith(" ") ? " " : "";
		ctx.ui.setEditorText(cur + sep + s);
	}
}

/** Register a file as a live attachment and return its `[Image #n]` token. */
function prepareFileAsToken(path: string): string | null {
	const data = readAttachData(path);
	if (!data) return null;
	const idx = nextIndex();
	attachments.set(idx, data);
	return `[Image #${idx}]`;
}

export default function (pi: ExtensionAPI) {
	// Live path -> [Image #n] conversion: re-scan the editor text (debounced)
	// after every keystroke and replace resolved image paths with tokens, so a
	// pasted/dropped/typed path shows up as `[Image #1]` in the input itself
	// rather than only after the message is sent. Interactive TUI only; the
	// hook is a no-op in print/rpc/json modes, which we also guard via ctx.mode.
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		convertedDisposed = false;
		attachments.clear();
		nextAttachIndex = 1;
		unsubTerminalInput?.();
		unsubTerminalInput = ctx.ui.onTerminalInput(() => {
			if (convertTimer) clearTimeout(convertTimer);
			// Defer so the editor has processed the keystroke (or paste/drop) before
			// we read its text; otherwise conversion lags by one character.
			convertTimer = setTimeout(() => {
				convertTimer = undefined;
				convertPathsToTokens(ctx);
			}, 60);
			return undefined;
		});
	});

	pi.on("session_shutdown", async () => {
		convertedDisposed = true;
		unsubTerminalInput?.();
		unsubTerminalInput = undefined;
		if (convertTimer) {
			clearTimeout(convertTimer);
			convertTimer = undefined;
		}
		attachments.clear();
		nextAttachIndex = 1;
	});

	// On submit, resolve every `[Image #n]` token (and any leftover literal
	// paths) to base64 image bytes and attach them as flat ImageContent, which
	// pi-ai's anthropic adapter turns into the provider's image block shape.
	pi.on("input", async (event, ctx) => {
		// Skip slash commands (/reload, /model gpt) but not absolute paths
		// (/Users/... has a second slash before any whitespace, so the slash-command
		// regex below does not match it).
		if (event.source === "extension" || /^\/[\w:-]+(\s|$)/.test(event.text)) {
			return { action: "continue" };
		}
		const { text, images } = finalizeForSubmit(event.text, event.images);
		if (images.length === (event.images?.length ?? 0) && text === event.text) {
			return { action: "continue" };
		}
		return { action: "transform", text, images };
	});

	pi.registerShortcut("ctrl+v", {
		description: "Paste image or copied file from clipboard as [Image #n]",
		handler: async (ctx) => {
			try {
				// 1) File reference(s) on the clipboard (Finder "Copy").
				const files = clipboardFilePaths();
				if (files.length > 0) {
					const inserts: string[] = [];
					for (const f of files) {
						const tok = prepareFileAsToken(f);
						if (tok) {
							inserts.push(tok);
						} else {
							// Over the size limit or unreadable — keep the literal path as text.
							inserts.push(f);
							try {
								if (statSync(f).size > MAX_ATTACH_BYTES) {
									ctx.ui.notify(`Skipped ${f} (over 5MB, left as path)`, "warning");
								}
							} catch {
								// Unreadable: surface as text anyway.
							}
						}
					}
					if (inserts.length > 0) insertTokensAtCursor(ctx, inserts);
					ctx.ui.notify(
						files.length === 1 ? "Pasted image" : `Pasted ${files.length} images`,
						"info",
					);
					return;
				}
				// 2) Image bytes on the clipboard -> write temp file -> token.
				const imagePath = await clipboardImageToTempFile();
				if (imagePath) {
					const tok = prepareFileAsToken(imagePath);
					insertTokensAtCursor(ctx, [tok ?? imagePath]);
					return;
				}
				ctx.ui.notify("Clipboard has no image or file to paste", "warning");
			} catch (error) {
				ctx.ui.notify(`Paste failed: ${(error as Error).message}`, "error");
			}
		},
	});
}