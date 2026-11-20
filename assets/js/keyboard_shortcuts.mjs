// Single-letter shortcuts for the event manager toggles.
// They must never fire while someone is typing (a reply, a poll, a form).

const EDITABLE_TAGS = new Set(["INPUT", "TEXTAREA", "SELECT"]);

export function isEditableTarget(target) {
  if (!target) return false;
  if (target.isContentEditable) return true;

  const tagName = (target.tagName || "").toUpperCase();
  return EDITABLE_TAGS.has(tagName);
}

export function handleShortcut(event, root = document) {
  if (event.ctrlKey || event.metaKey || event.altKey || event.repeat) return false;
  if (isEditableTarget(event.target)) return false;
  if (typeof event.key !== "string" || event.key.length !== 1) return false;

  const key = event.key.toUpperCase();
  const button = Array.from(root.querySelectorAll("[data-shortcut]")).find(
    (candidate) => !candidate.disabled && (candidate.dataset.shortcut || "").toUpperCase() === key,
  );

  if (!button) return false;

  event.preventDefault();
  button.click();
  return true;
}

export function installShortcuts(target = window, root = document) {
  const listener = (event) => handleShortcut(event, root);
  target.addEventListener("keydown", listener);
  return () => target.removeEventListener("keydown", listener);
}
