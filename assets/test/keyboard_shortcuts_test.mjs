import assert from "node:assert/strict";
import test from "node:test";

const { isEditableTarget, handleShortcut } = await import("../js/keyboard_shortcuts.mjs");

function target(tagName, extra = {}) {
  return { tagName, isContentEditable: false, closest: () => null, ...extra };
}

function keyEvent(key, eventTarget, extra = {}) {
  const event = {
    key,
    target: eventTarget,
    ctrlKey: false,
    metaKey: false,
    altKey: false,
    repeat: false,
    defaultPrevented: false,
    preventDefault() {
      this.defaultPrevented = true;
    },
    ...extra,
  };
  return event;
}

function rootWith(buttons) {
  return {
    querySelectorAll: () => buttons,
  };
}

function shortcutButton(shortcut, { disabled = false } = {}) {
  return {
    dataset: { shortcut },
    disabled,
    clicks: 0,
    click() {
      this.clicks += 1;
    },
  };
}

test("text fields, selects and editable areas are editable targets", () => {
  assert.equal(isEditableTarget(target("INPUT")), true);
  assert.equal(isEditableTarget(target("TEXTAREA")), true);
  assert.equal(isEditableTarget(target("SELECT")), true);
  assert.equal(isEditableTarget(target("DIV", { isContentEditable: true })), true);
  assert.equal(isEditableTarget(target("BUTTON")), false);
  assert.equal(isEditableTarget(target("BODY")), false);
  assert.equal(isEditableTarget(null), false);
});

test("a letter typed in a reply field does not trigger a shortcut", () => {
  const button = shortcutButton("A");
  const handled = handleShortcut(keyEvent("a", target("INPUT")), rootWith([button]));

  assert.equal(handled, false);
  assert.equal(button.clicks, 0);
});

test("a letter pressed outside text fields triggers the matching shortcut once", () => {
  const first = shortcutButton("Q");
  const duplicate = shortcutButton("Q");
  const other = shortcutButton("W");
  const event = keyEvent("q", target("BODY"));

  const handled = handleShortcut(event, rootWith([other, first, duplicate]));

  assert.equal(handled, true);
  assert.equal(first.clicks, 1);
  assert.equal(duplicate.clicks, 0);
  assert.equal(other.clicks, 0);
  assert.equal(event.defaultPrevented, true);
});

test("modifier keys, repeats and disabled toggles are ignored", () => {
  const button = shortcutButton("D");
  const disabled = shortcutButton("E", { disabled: true });
  const root = rootWith([button, disabled]);

  assert.equal(handleShortcut(keyEvent("d", target("BODY"), { ctrlKey: true }), root), false);
  assert.equal(handleShortcut(keyEvent("d", target("BODY"), { metaKey: true }), root), false);
  assert.equal(handleShortcut(keyEvent("d", target("BODY"), { repeat: true }), root), false);
  assert.equal(handleShortcut(keyEvent("e", target("BODY")), root), false);
  assert.equal(button.clicks, 0);
  assert.equal(disabled.clicks, 0);
});

test("only elements that declare a shortcut are considered", () => {
  const button = shortcutButton("Q");
  const selectors = [];
  const root = {
    querySelectorAll(selector) {
      selectors.push(selector);
      return [button];
    },
  };

  handleShortcut(keyEvent("q", target("BODY")), root);

  assert.deepEqual(selectors, ["[data-shortcut]"]);
});

test("Escape and other named keys pass through untouched", () => {
  const button = shortcutButton("Q");
  const event = keyEvent("Escape", target("BODY"));

  assert.equal(handleShortcut(event, rootWith([button])), false);
  assert.equal(event.defaultPrevented, false);
  assert.equal(button.clicks, 0);
});

test("installShortcuts registers one keydown listener and can remove it", async () => {
  const { installShortcuts } = await import("../js/keyboard_shortcuts.mjs");
  const listeners = new Map();
  const fakeWindow = {
    addEventListener: (type, fn) => listeners.set(type, fn),
    removeEventListener: (type, fn) => listeners.get(type) === fn && listeners.delete(type),
  };
  const button = shortcutButton("W");

  const uninstall = installShortcuts(fakeWindow, rootWith([button]));
  listeners.get("keydown")(keyEvent("w", target("BODY")));
  assert.equal(button.clicks, 1);

  uninstall();
  assert.equal(listeners.has("keydown"), false);
});
