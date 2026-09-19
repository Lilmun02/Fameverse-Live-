// HOST LIVE HARD RESET
//
// The retired Host Live implementation has been deliberately removed from the
// active app before the replacement is built. Keep this module as a zero-render
// tombstone so the existing App route remains stable while the new single-shell
// Host Live is designed and wired from scratch.
//
// Do not restore old Host Live markup, classes, CSS, or platform-specific shells
// here. The replacement must be one canonical host Live build for every device.
export default function LiveScreen() {
  return null
}
